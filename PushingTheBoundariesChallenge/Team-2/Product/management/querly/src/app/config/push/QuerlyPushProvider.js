"use client"

import { ChatStreamInitializerProvider } from "./ChatStreamInitializer";

export default function QuerlyPushProvider({children}){
    return(<>
        <ChatStreamInitializerProvider>
            {children}
        </ChatStreamInitializerProvider>
    </>)
}