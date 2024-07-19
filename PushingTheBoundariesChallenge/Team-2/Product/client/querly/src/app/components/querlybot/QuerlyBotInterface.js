import React, { useState, useEffect, useRef } from "react";
import styles from "./styles/QuerlyBotInterface.module.css";
import '@flaticon/flaticon-uicons/css/all/all.css';
import { useChatStream } from "@/app/config/push/ChatStreamInitializer";
import { CONSTANTS } from "@pushprotocol/restapi";
import PushStore from "@/app/config/store/PushStore";
import { useRecoilState } from "recoil";

export default function QuerlyBotInterface() {
    const { stream, isStreamConnected, isStreamInitialized, pushUser, setPushUser } = useChatStream();
    const [queryInput, setQueryInput] = useState("");
    const [pushStoreState, setPushStoreState] = useRecoilState(PushStore.pushUser);
    const streamRef = useRef(stream); // Use ref to keep a stable reference for the stream object
    const isListenerAdded = useRef(false); // Flag to ensure listener is added only once

    const handleInputChange = (event) => {
        setQueryInput(event.target.value);
    };

    const getQueryRequest = () => {
        return JSON.stringify({
            subscriber: process.env.NEXT_PUBLIC_SUBSCRIBER_ADDRESS,
            route: window.location.href,
            type: "query",
            query: queryInput,
        });
    };

    useEffect(() => {
        const handleMessage = async (message) => {
            if (["chat.message", "chat.request"].includes(message.event) && message.message.content) {
                console.log(message);

                // Parse the message content
                const parsedContent = JSON.parse(message.message.content);
                const updatedMessage = { ...message };

                // Extract query for self and response for other
                if (message.origin === "self") {
                    updatedMessage.query = parsedContent.query;
                } else if (message.origin === "other") {
                    updatedMessage.response = parsedContent.response;
                }

                setPushStoreState((prevState) => ({
                    ...prevState,
                    userChats: prevState.userChats ? [...prevState.userChats, updatedMessage] : [updatedMessage]
                }));
            }
        };

        if (streamRef.current && !isListenerAdded.current) {
            streamRef.current.on(CONSTANTS.STREAM.CHAT, handleMessage);
            isListenerAdded.current = true; // Mark the listener as added
        }

        // Cleanup function to remove the event listener
        return () => {
            if (streamRef.current) {
                streamRef.current.off(CONSTANTS.STREAM.CHAT, handleMessage);
                isListenerAdded.current = false; // Reset the flag when component unmounts
            }
        };
    }, [setPushStoreState]); // Dependency array includes only setPushStoreState


    const getTicketRequest = () => {
        return JSON.stringify({
            subscriber: process.env.NEXT_PUBLIC_SUBSCRIBER_ADDRESS,
            route: window.location.href,
            type: "ticket",
            query: "Open Ticket",
        });
    };

    const sendQuery = async () => {
        if (queryInput.length > 0) {
            setQueryInput("")
            const queryRequest = getQueryRequest();
            await pushUser.chat.send(process.env.NEXT_PUBLIC_QUERLY_BOT_ADDRESS, {
                type: 'Text',
                content: queryRequest,
            });
        }
    };


    const openTicket = async () => {
        const ticketRequest = getTicketRequest();
        await pushUser.chat.send(process.env.NEXT_PUBLIC_QUERLY_BOT_ADDRESS, {
            type: 'Text',
            content: ticketRequest,
        });
    }

    return (
        <div className={styles.querlyBotInterface}>
            <div className={styles.querlyBotInterfaceContainer}>
                <div className={styles.querlyBotChats}>
                    <div className={styles.querlyBotChatsHeader}>
                        <i className="fi fi-sr-hand-wave"></i>
                        <p>
                            <b>Hi</b> this is querly bot. Ask your queries regarding this route.
                        </p>
                    </div>
                    <div className={styles.chatMessages}>
                        {pushStoreState.userChats && pushStoreState.userChats.map((chat, index) => (
                            <div key={index} className={chat.origin === "self" ? styles.chatMessageSelf : styles.chatMessageOther}>
                                {chat.origin === "self" && (
                                    <>
                                        <p>{chat.query}</p>
                                    </>
                                )}
                                {chat.origin === "other" && (
                                    <>  
                                        <p><small>
                                            {chat.type}
                                            </small>{chat.response}</p>
                                        {chat.response==="I am sorry I couldn't resolve your query! Do you need me to connect you with admin?" &&
                                            <div className={styles.additionalResponses}>
                                                <div className={styles.additionalResponseOption} onClick={()=> openTicket()}>
                                                    Open Ticket
                                                </div>
                                                <div className={styles.additionalResponseOption}>
                                                    Visit Forums
                                                </div>
                                            </div>
                                        }
                                    </>
                                )}
                            </div>
                        ))}
                    </div>
                </div>
                <div className={styles.querlyBotInterfaceInput}>
                    <form
                        onSubmit={(e) => {
                            e.preventDefault();
                            sendQuery();
                        }}
                    >
                        <input
                            type="text"
                            placeholder="Enter your query!"
                            value={queryInput}
                            onChange={handleInputChange}
                        />
                        <div
                            className={styles.querlyBotInterfaceInputSubmit}
                            onClick={sendQuery}
                        >
                            <i className="fi fi-sr-arrow-circle-up"></i>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    );
}
