"use client";

import React, { createContext, useState, useEffect, useCallback,useContext } from 'react';
import { CONSTANTS } from '@pushprotocol/restapi';
import PushStore from '../store/PushStore';
import { useRecoilState } from "recoil";
import { PushAPI } from '@pushprotocol/restapi';
import { useAccount, useChainId, useWalletClient } from 'wagmi';

export const ChatsStreamContext = createContext();

export const ChatStreamInitializerProvider = ({ children }) => {
    const [pushStoreState,setPushStoreState] = useRecoilState(PushStore.pushUser);
    const [pushUser, setPushUser] = useState(null);
    const [stream, setStream] = useState(null);
    const [isStreamConnected, setIsStreamConnected] = useState(false);
    const [isStreamInitialized, setIsStreamInitialized] = useState(false);
    const { address,isConnected } = useAccount();
    const chainId = useChainId();
    const { data: walletClient } = useWalletClient({ chainId });
    const pushENV = CONSTANTS.ENV.STAGING;

    const initializePushUser = useCallback(async () => {
        if (!pushUser && pushStoreState.initializedUser && walletClient ) {
            try {
                console.log("Re-Initializing Push User...");
                const result = await PushAPI.initialize(walletClient, {
                    decryptedPGPPrivateKey: pushStoreState.initializedUser.decryptedPgpPvtKey,
                    env: pushENV,
                    account: address,
                });
                setPushUser(result);
            } catch (error) {
                console.error("Failed to initialize push user:", error);
            }
        }
    }, [pushUser, pushStoreState.initializedUser, walletClient, address]);

    const reconnectStream = useCallback(async (currentStream) => {
        if (!currentStream || !pushStoreState.initializedUser) return;
        try {
            await currentStream.connect();
        } catch (error) {
            console.error("Failed to reconnect stream:", error);
        }
    }, [pushStoreState.initializedUser]);

    const initializeStream = useCallback(async () => {
        if (!pushUser || isStreamInitialized || !pushStoreState.initializedUser) return;

        try {
            console.log("Initializing Stream...");
            const newStream = await pushUser.initStream(
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
                }
            );

            newStream.on(CONSTANTS.STREAM.CONNECT, () => {
                setIsStreamConnected(true);
            });

            newStream.on(CONSTANTS.STREAM.DISCONNECT, () => {
                setIsStreamConnected(false);
                if (pushStoreState.initializedUser && stream) {
                    reconnectStream(stream);
                }
            });

            

            await newStream.connect();
            setStream(newStream);
            setIsStreamInitialized(true);
        } catch (error) {
            console.error("Failed to initialize stream:", error);
        }
    }, [pushUser, isStreamInitialized, pushStoreState.initializedUser, reconnectStream, stream]);

    useEffect(() => {
        setPushStoreState(prevState => ({
            ...prevState,
             userChats: null,
        }));
        initializePushUser();
    }, [initializePushUser]);

    useEffect(() => {
        initializeStream();
        return () => {
            if (stream) {
                stream.disconnect();
                if (pushStoreState.initializedUser) {
                    reconnectStream(stream);
                }
            }
        };
    }, [initializeStream, stream, pushStoreState.initializedUser, reconnectStream]);

    return (
        <ChatsStreamContext.Provider value={{ stream, isStreamConnected, isStreamInitialized, pushUser, setPushUser }}>
            {children}
        </ChatsStreamContext.Provider>
    );
}

export const useChatStream = () => {
    const context = useContext(ChatsStreamContext);
    if (context === undefined) {
      throw new Error('useChatStream must be used within a ChatStreamInitializerProvider');
    }
    return context;
};