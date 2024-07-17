// Import required libraries and modules
require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const WebSocket = require('ws');
const WaveFile = require('wavefile').WaveFile;
const { PushAPI, CONSTANTS } = require('@pushprotocol/restapi');
const { ethers } = require('ethers');
const { initCallData, updateTranscript, updateOnDisconnect } = require('./src/firebase');
const { analyzePriority } = require('./src/utils');

// Initialize Express app and WebSocket server
const app = express();
app.use(bodyParser.urlencoded({ extended: true }));
const server = require('http').createServer(app);
const wss = new WebSocket.Server({ server });

let chunks = [];
let callerMap = {}; //[msg.streamSid] = msg.callSid;
let assemblyAIWSMap = {}; //[msg.callSid]: assemblyAIWSConnection

// Define the async function to encapsulate the logic
async function initializePushProtocol() {
  const signer = new ethers.Wallet(
    `0x${process.env.WALLET_PRIVATE_KEY}`
  );

  const userAlice = await PushAPI.initialize(signer, {
    env: CONSTANTS.ENV.STAGING,
  });

  return userAlice;
}

// Initialize Push Protocol once
const userAlicePromise = initializePushProtocol();

wss.on('connection', (ws) => {
  console.info('New Connection Initiated');

  ws.on('message', async (message) => {
    const msg = JSON.parse(message);
    const callSid = msg.start?.callSid ?? callerMap[msg.streamSid];
    const assembly = assemblyAIWSMap[callSid];

    switch (msg.event) {
      case 'connected':
        console.info('A new call has been connected.');
        break;

      case 'start':
        console.info('Starting media stream...');
        console.info(`callSid: ${msg.start.callSid}`);

        callerMap[msg.streamSid] = msg.start.callSid;

        const texts = {};

        assembly.onmessage = async (assemblyMsg) => {
          let transcript = '';
          const res = JSON.parse(assemblyMsg.data);
          console.log('Received from AssemblyAI:', res); 
          texts[res.audio_start] = res.text;
          const keys = Object.keys(texts);
          keys.sort((a, b) => a - b);
          for (const key of keys) {
            if (texts[key]) {
              transcript += ` ${texts[key]}`;
            }
          }

          const priority = analyzePriority(transcript);
          updateTranscript(callSid, msg.streamSid, transcript, priority);

          // Send notification using Push Protocol
          const userAlice = await userAlicePromise;
          await userAlice.channel.send(['*'], {
            notification: {
              title: 'Emergency',
              body: transcript,
            },
          });
        };
        break;

      case 'media':
        const twilioData = msg.media.payload;

        // Build the wav file from scratch since it comes in as raw data
        let wav = new WaveFile();
        wav.fromScratch(1, 8000, '8m', Buffer.from(twilioData, 'base64'));
        wav.fromMuLaw();

        const twilio64Encoded = wav.toDataURI().split('base64,')[1];
        const twilioAudioBuffer = Buffer.from(twilio64Encoded, 'base64');
        chunks.push(twilioAudioBuffer.slice(44));

        // We have to chunk data b/c twilio sends audio durations of ~20ms and AAI needs a min of 100ms
        if (chunks.length >= 5) {
          const audioBuffer = Buffer.concat(chunks);
          const encodedAudio = audioBuffer.toString('base64');

          // Send data to Assembly AI and clear chunks
          assembly.send(JSON.stringify({ audio_data: encodedAudio }));
          chunks = [];
        }
        break;

      case 'stop':
        console.info('Call has ended');
        assembly.send(JSON.stringify({ terminate_session: true }));
        updateOnDisconnect(callerMap[msg.streamSid]);
        setTimeout(() => {
          assembly.close();
          delete assemblyAIWSMap[callSid];
        }, 100); // Adjust timeout as needed
        break;
    }
  });
});

app.get('/', (_, res) => res.send('Twilio Live Stream App'));

app.post('/', async (req, res) => {
  const callSid = req.body.CallSid;

  console.log('Webhook received');

  assemblyAIWSMap[callSid] = new WebSocket('wss://api.assemblyai.com/v2/realtime/ws?sample_rate=8000', {
    headers: { authorization: process.env.ASSEMBLYAI_API_KEY },
  });
  assemblyAIWSMap[callSid].onerror = console.error;

  initCallData(callSid, req.body);

  res.set('Content-Type', 'text/xml');
  res.send(
    `<Response>
       <Start>
         <Stream url='wss://${req.headers.host}' />
       </Start>
       <Say>
        Thank you for calling 911. All operators are currently busy.
        Your call will be answered by an AI assistant trained to help in emergency situations.
        Please remain on the line and provide your name, location and the nature of your emergency so that we can assist you.
       </Say>
       <Pause length='60' />
     </Response>`
  );
});

server.listen(8080, () => {
  console.log('Listening on Port 8080', process.env.ASSEMBLYAI_API_KEY);

  const testWS = new WebSocket('wss://api.assemblyai.com/v2/realtime/ws?sample_rate=8000', {
    headers: { authorization: process.env.ASSEMBLYAI_API_KEY },
  });

  testWS.onopen = () => {
    console.info('Test WebSocket connection opened successfully');
    testWS.close();
  };

  testWS.onerror = (error) => {
    console.error('Test WebSocket connection error:', error);
  };

  testWS.onclose = () => {
    console.info('Test WebSocket connection closed');
  };
});

const exitHandler = (exitCode = 0) =>
  function () {
    console.log('Gracefully terminating assemblyai connection', arguments);

    for (const assembly of Object.values(assemblyAIWSMap)) {
      if (assembly) {
        assembly.send(JSON.stringify({ terminate_session: true }));
        assembly.close();
      }
    }
    process.exit(exitCode);
  };

process.on('uncaughtException', exitHandler(1));
process.on('unhandledRejection', exitHandler(1));
process.on('SIGTERM', exitHandler(0));
process.on('SIGINT', exitHandler(0));
