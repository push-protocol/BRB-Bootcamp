"use client"

import React,{useEffect, useState} from "react";
import { PushAPI,CONSTANTS } from "@pushprotocol/restapi";
import PushStore from "../config/store/PushStore";
import { useWalletClient,useChainId } from "wagmi";
import { pushENV } from "@/lib/secure/Config";
import { useRecoilState } from "recoil";

export default function InitializePush(){
    const [pushUserStoreState,setPushUserStoreState] = useRecoilState(PushStore.pushUser);
    const [isLoading, setIsLoading] = useState(false);
    const chainId = useChainId()
    const { data: walletClient } = useWalletClient({ chainId });


    const handleConnect = async ()  => {
        setIsLoading(true); 
        try{
            if(walletClient){
                const user = await PushAPI.initialize(walletClient, {
                    env: pushENV,
                });
                if(!user.errors.length > 0){
                    setPushUserStoreState((prevState) => ({
                        ...prevState,
                        initializedUser: user,
                    }))
                }
            }
        }catch{
            console.log("Error initializing PUSH API:", error);
        }finally{
            setIsLoading(false); 
        }
    }

    return {handleConnect,isLoading};
    
}

