"use client"

import { QuerlyConnectKitProvider } from "./connectkit/QuerlyConnectkitProvider";
import { RecoilRoot } from "recoil";
import { MetaConfigProvider } from "./MetaConfig";
import QuerlyPushProvider from "./push/QuerlyPushProvider";


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