"use client";

import React, { createContext, useContext, useEffect } from 'react';
import { useAccount } from 'wagmi';
import { useRecoilState } from 'recoil';
import PushStore from './store/PushStore';
import { useChatStream } from './push/ChatStreamInitializer';

const MetaConfigContext = createContext();

export function MetaConfigProvider({ children }) {
    const [pushUserStoreState, setPushUserStoreState] = useRecoilState(PushStore.pushUser);
    const { isDisconnected, status } = useAccount();
    const {setPushUser} = useChatStream();

    useEffect(() => {
        if ((status === "disconnected" && isDisconnected)) {
            if (pushUserStoreState.initializedUser !== null) {
                setPushUserStoreState((prevState) => ({
                    ...prevState,
                    initializedUser: null,
                    userChats: null,
                }));
                
                setPushUser(null);
            }
        }
    }, [isDisconnected, status, pushUserStoreState.initializedUser, setPushUserStoreState]);

    return (
        <MetaConfigContext.Provider value={{}}>
            {children}
        </MetaConfigContext.Provider>
    );
}

export function useMetaConfig() {
    const context = useContext(MetaConfigContext);
    if (context === undefined) {
        throw new Error('useMetaConfig must be used within a MetaConfigProvider');
    }
    return context;
}