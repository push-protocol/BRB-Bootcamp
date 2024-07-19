"use client"

import React,{useState} from "react";
import { useRouter } from "next/navigation";

export default function RouterPushLink() {
    const [isRouterLinkOpening,setIsRouterLinkOpening] = useState(false);
    const router = useRouter();

    const routeTo = async (link) => {
        setIsRouterLinkOpening(true);
        try{
            await new Promise(resolve => setTimeout(resolve, 500));
            router.push(link);
        }catch{
            console.log("Something went wrong in opening link!")
        }finally{
            setIsRouterLinkOpening(false);
        }
    };

    return {routeTo,isRouterLinkOpening}
}