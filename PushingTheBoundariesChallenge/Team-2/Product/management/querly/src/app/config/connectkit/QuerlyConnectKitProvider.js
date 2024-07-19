"use client"

import React from "react";
import { WagmiProvider, createConfig } from 'wagmi';
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { skaleCalypsoTestnet } from 'viem/chains';
import { ConnectKitProvider, getDefaultConfig, SIWEProvider } from 'connectkit';
import ConnectKitAvatarConfig from "./ConnecKitAvatarConfig";
import { walletConnectID } from "@/lib/secure/Config";
import { SiweMessage } from 'siwe';

const config = createConfig(
	getDefaultConfig({
		appName: "Querly",
		chains: [skaleCalypsoTestnet],
		walletConnectProjectId: walletConnectID,
		appDescription: "Querly: The Query Management System for Web3 dapps",
		appUrl: "https://querly.xyz", //Not owned by us.
        appIcon:"https://gold-select-penguin-939.mypinata.cloud/ipfs/QmNZcV1KjZB4GLkHfj7ekw6xSF9ZCVBwyyTrAM7UFYCLE5",
	})
    
);

const siweConfig = {
	getNonce: async () => {
		const res = await fetch(`/siwe`, { method: 'PUT' });
		if (!res.ok) throw new Error('Failed to fetch SIWE nonce');

		return res.text();
	},
	createMessage: ({ nonce, address, chainId }) => {
		return new SiweMessage({
			nonce,
			chainId,
			address,
			version: '1',
			uri: window.location.origin,
			domain: window.location.host,
			statement: 'Querly Signature Authentication. Click Sign-In and proceed. This request will not trigger a blockchain transaction or cost any gas fees. Have a GoodDay!',
            }).prepareMessage();
	},
	verifyMessage: async ({ message, signature }) => {
		const res = await fetch(`/siwe`, {
			method: 'POST',
			body: JSON.stringify({ message, signature }),
			headers: { 'Content-Type': 'application/json' },
		});
		return res.ok;
	},
	getSession: async () => {
		const res = await fetch(`/siwe`);
		if (!res.ok) throw new Error('Failed to fetch SIWE session');

		const { address, chainId } = await res.json();
		return address && chainId ? { address, chainId } : null;
	},
	signOut: async () => {
		const res = await fetch(`/siwe`, { method: 'DELETE' });
		return res.ok;
	}
};

const queryClient = new QueryClient();

export const QuerlyConnectKitProvider = ({children}) => {
    return(<>
        <WagmiProvider config={config}>
            <QueryClientProvider client={queryClient}>   
                <SIWEProvider {...siweConfig}>
                    <ConnectKitProvider 
                        theme="midnight" 
                        options={{
                        customAvatar: ConnectKitAvatarConfig,
                        }}
                        customTheme={{
                            "--ck-font-family": '"Sen", sans-serif',
                        }}
                    >
                        {children}     
                    </ConnectKitProvider>
                </SIWEProvider>
            </QueryClientProvider>
        </WagmiProvider>
    </>)
}
