import restana from "restana";
import { PushAPI, CONSTANTS } from '@pushprotocol/restapi';
import { ethers } from 'ethers';
import dotenv from 'dotenv';
import { skaleRpcUrl, ticketingContract, subscriptionContract } from "./helpers/Consts.js";
import abi from "./contracts/subscription/abi/abi.json" assert { type: "json" };
import ticketabi from "./contracts/Ticketing/abi/abi.json" assert { type: "json" };
import { addDocument, queryAndRespond } from "./commands/Org.js";

dotenv.config();

const signer = new ethers.Wallet(process.env.WALLET_PRIVATE_KEY);

export const pushBotInitializer = await PushAPI.initialize(signer, {
    env: CONSTANTS.ENV.STAGING,
});

const stream = await pushBotInitializer.initStream(
    [
        CONSTANTS.STREAM.CHAT, 
        CONSTANTS.STREAM.NOTIF, 
        CONSTANTS.STREAM.CONNECT, 
        CONSTANTS.STREAM.DISCONNECT,
    ],
    {
        filter: {
            chats: ["*"],
        },
        connection: {
            retries: 3,
        },
        raw: false,
    },
);

const providerUrl = skaleRpcUrl;
const provider = new ethers.providers.JsonRpcProvider(providerUrl);
const subscriptionContractAddress = subscriptionContract;
const ticketingContractAddress = ticketingContract;

const wallet = new ethers.Wallet(process.env.WALLET_PRIVATE_KEY, provider);
const subscription = new ethers.Contract(subscriptionContractAddress, abi, wallet);
const ticketing = new ethers.Contract(ticketingContractAddress, ticketabi, wallet);

async function checkIsSubscribed(senderAddress) {
    return await subscription.isSubscribed(senderAddress);
}

async function createNewTicket(userAddress, subscriber,chatId) {
    try {
        const ticketId = await ticketing.openTicket(userAddress, subscriber);
        sendResponseMessage(JSON.stringify({
            type: "ticket",
            response: "Your Ticket is Opened with ID. Please wait, our admins will reach you anytime soon."
        }), chatId);
    } catch (error) {
        if (error.message.includes("Previous ticket must be closed before opening a new one")) {
            sendResponseMessage(JSON.stringify({
                type: "ticket",
                response: "A ticket is already open. Please wait while our admins contact you, or you can visit our forums for assistance."
            }), chatId);
        } else {
            console.error("Error opening ticket:", error);
            sendResponseMessage(JSON.stringify({
                type: "error",
                response: "Failed to open the ticket. Please try again later."
            }), chatId);
        }
    }
}


async function sendResponseMessage(message, recipient) {
    try {
        await pushBotInitializer.chat.send(recipient, {
            type: 'Text',
            content: message,
        });
    } catch (error) {
        console.log("Response Sending failed", error);
    }
}

function escapeTemplateString(str) {
    return str.replace(/[`$]/g, match => `\\${match}`);
}

stream.on(CONSTANTS.STREAM.CHAT, async (message) => {
    try {
        if (message.origin === "other" && ["chat.message", "chat.request"].includes(message.event) && message.message.content) {
            const senderAddress = message.from.replace("eip155:", "");
            const messageContent = JSON.parse(message.message.content);
            const isSubscribed = await checkIsSubscribed(messageContent.subscriber);

            if (message.event === "chat.request") {
                await pushBotInitializer.chat.accept(message.chatId);
            }

            if (isSubscribed) {
                if (messageContent.subscriber === senderAddress) {
                    if (messageContent.type === "store") {
                        addDocument(`${messageContent.subscriber}${messageContent.route}`, messageContent.info)
                            .then(() => sendResponseMessage(JSON.stringify({
                                type: "store",
                                response: `Info Stored for route: ${messageContent.route}`
                            }), message.chatId))
                            .catch(error => {
                                console.error("Error storing document:", error);
                                sendResponseMessage(JSON.stringify({
                                    type: "error",
                                    response: "Failed to store info. Please check the format."
                                }), message.chatId);
                            });
                    }
                }

                if (messageContent.type === "query") {
                    const response = await queryAndRespond(`${messageContent.subscriber}${messageContent.route}`, messageContent.query);
                    sendResponseMessage(JSON.stringify({
                        type: "query",
                        response: response.content || "I am sorry I couldn't resolve your query! Do you need me to connect you with admin?"
                    }), message.chatId);
                }

                if (messageContent.type === "ticket") {
                    try {
                        await createNewTicket(senderAddress, messageContent.subscriber,message.chatId);
                    } catch (error) {
                        console.error("Error opening ticket:", error);
                        sendResponseMessage(JSON.stringify({
                            type: "error",
                            response: "Failed to open the ticket. Please try again later."
                        }), message.chatId);
                    }
                }
            } else {
                sendResponseMessage(JSON.stringify({
                    type: "error",
                    response: "User is not subscribed."
                }), message.chatId);
            }
        }
    } catch (error) {
        console.error("Error handling chat message:", error);
        sendResponseMessage(JSON.stringify({
            type: "error",
            response: "Something Went Wrong! Check the Message format"
        }), message.chatId);
    }
});

stream.connect();

const service = restana();
service.get('/hi', (req, res) => res.send('Hello World!'));

service.start(3001);
