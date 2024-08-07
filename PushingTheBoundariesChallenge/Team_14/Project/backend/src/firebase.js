require('dotenv').config();
const { initializeApp } = require('firebase/app');
const { getDatabase, ref, set, update, get } = require('firebase/database');
const { getCoordinates, analyzeTranscript, getNamedEntities } = require('./utils');

const app = initializeApp({
  apiKey: process.env.FIREBASE_API_KEY,
  authDomain: process.env.FIREBASE_AUTH_DOMAIN,
  databaseURL: process.env.FIREBASE_DATABASE_URL,
  projectId: process.env.FIREBASE_PROJECT_ID,
  storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.FIREBASE_APP_ID,
});

const db = getDatabase(app);

module.exports.initCallData = (callSid, payload) => {
  if (!callSid) {
    return;
  }

  return set(ref(db, `/calls/${callSid}`), {
    dateCreated: new Date().toISOString(),
    emergency: '',
    // geocode: undefined,
    // location: undefined,
    live: true,
    name: payload.CallerName || 'Unknown Caller',
    phone: payload.From || 'Unknown Number',
    priority: 'TBD', // HIGH | MEDIUM | LOW | TBD
    status: 'OPEN', // 'OPEN' | 'DISPATCHED' | 'RESOLVED'
    transcript: '',
  });
};

const updateNamedEntitiesWithExpensiveModel = (transcript, callSid) =>
  getNamedEntities(transcript, true).then(async ({ name, location }) => {
    const updates = {};
    if (name) {
      console.log('[Expensive Model] Found name:\t', name);
      updates.name = name;
    }

    if (location) {
      console.log('[Expensive Model] Found location:\t', location);
      updates.location = location;

      const coordinates = await getCoordinates(location);
      if (coordinates.lat && coordinates.lng) {
        updates.geocode = coordinates;
      }
    }

    return update(ref(db, `/calls/${callSid}`), updates);
  });

module.exports.updateOnDisconnect = async (callSid) => {
  if (!callSid) {
    return;
  }

  const updates = {
    live: false,
    dateDisconnected: new Date().toISOString(),
  };

  const snapshot = await get(ref(db, `/calls/${callSid}/transcript`));

  if (snapshot.exists()) {
    const transcript = snapshot.val();

    if (!transcript) {
      console.warn('Transcript is empty, will not analyze');
      return;
    }

    console.log('Final transcript:\t', transcript);

    const { name, location, emergencyType } = await analyzeTranscript(transcript);

    if (location) {
      console.log('Found location:\t', location);
      updates.location = location;

      const coordinates = await getCoordinates(location);
      if (coordinates.lat && coordinates.lng) {
        updates.geocode = coordinates;
      }
    }

    // override because the caller has announced their name which is more accurate
    if (name) {
      console.log('Found name:\t', name);
      updates.name = name;
    }

    if (emergencyType) {
      console.log('Found emergencyType:\t', emergencyType);
      updates.emergency = emergencyType;
    }

    // Whenever this resolves => override previous model's result
    updateNamedEntitiesWithExpensiveModel(transcript, callSid);
  }

  return update(ref(db, `/calls/${callSid}`), updates);
};

module.exports.updateTranscript = (callSid, streamSid, transcript, priority) => {
  if (!callSid) {
    return;
  }

  return update(ref(db, `/calls/${callSid}`), {
    callSid,
    streamSid,
    transcript,
    priority,
  });
};
