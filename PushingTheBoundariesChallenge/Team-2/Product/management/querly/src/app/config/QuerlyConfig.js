"use client"

import { QuerlyConnectKitProvider } from "./connectkit/QuerlyConnectKitProvider"
import { RecoilRoot } from "recoil";
import QuerlyPushProvider from "./push/QuerlyPushProvider";
import { MetaConfigProvider } from "./MetaConfig";


export default function QuerlyConfig({children}){
    return(<>
        <QuerlyConnectKitProvider>
            <RecoilRoot>
                <QuerlyPushProvider>
                    <MetaConfigProvider>
                        {children}
                    </MetaConfigProvider>
                </QuerlyPushProvider>
            </RecoilRoot>
        </QuerlyConnectKitProvider>
    </>)
}