"use client"

import React from "react";
import { WagmiProvider, createConfig } from 'wagmi';
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { sepolia } from 'viem/chains';
import { ConnectKitProvider, getDefaultConfig } from 'connectkit';

const config = createConfig(
	getDefaultConfig({
		appName: "Querly",
		chains: [sepolia],
		walletConnectProjectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID,
		appDescription: "Querly: The Query Management System for Web3 dapps",
		appUrl: "https://querly.xyz", //Not owned by us.
        appIcon:"https://gold-select-penguin-939.mypinata.cloud/ipfs/QmNZcV1KjZB4GLkHfj7ekw6xSF9ZCVBwyyTrAM7UFYCLE5",
	})
);

const queryClient = new QueryClient();

export const QuerlyConnectKitProvider = ({children}) => {
    return(<>
        <WagmiProvider config={config}>
            <QueryClientProvider client={queryClient}>   
                    <ConnectKitProvider 
                        theme="midnight" 
                        customTheme={{
                            "--ck-font-family": '"Sen", sans-serif',
                        }}
                    >
                        {children}     
                    </ConnectKitProvider>
            </QueryClientProvider>
        </WagmiProvider>
    </>)
}