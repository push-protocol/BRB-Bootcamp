"use client"

import { useSIWE } from "connectkit";
import { useDisconnect } from "wagmi";


export default function DisconnectFunction(){
    const { signOut } = useSIWE();
    const { disconnect, isPending: isDisconnecting, } = useDisconnect();

    const handleWalletDisconnect = () => {
        signOut();
        disconnect();
    }

    return {handleWalletDisconnect,isDisconnecting}
}