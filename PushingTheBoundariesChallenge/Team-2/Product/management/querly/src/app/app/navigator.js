"use client"

import React,{useEffect} from "react"
import styles from "./styles/Navigator.module.css";
import '@flaticon/flaticon-uicons/css/all/all.css';
import Link from "next/link";
import QuerlyLogoTag from "@/../public/assets/svg/QuerlyLogoTag.svg";
import { usePathname } from "next/navigation";
import DisconnectFunction from "../helpers/WalletDisconnectFunction";
import { useAccount } from "wagmi";
import PushStore from "../config/store/PushStore";
import { useSIWE } from "connectkit";
import { useRecoilState,useRecoilValue } from "recoil";

export default function Navigator(){
    const pathname = usePathname();
    const isActive = (path) => pathname.startsWith(path);
    const {handleWalletDisconnect,isDisconnecting} = DisconnectFunction();
    const {isConnected,status:accountStatus} = useAccount();
    const {isSignedIn,signOut,isReady:siweStatus} = useSIWE();
    const pushUser = useRecoilValue(PushStore.pushUser)

    useEffect(()=>{
        if (accountStatus==="disconnected" || pushUser.initializedUser === null) {
            signOut();
            location.replace("/")
        }
    }, [isConnected, signOut,accountStatus]);

    return(<>
        <div className={styles.navigatorContainer}>
            <Link href={"/app"} className={styles.navigatorHeader}>
                <QuerlyLogoTag />
            </Link>
            <div className={styles.navigatorOptions}>
                <Link href={"/app/organization"} className={`${isActive("/app/organization") ? `${styles.navigatorOptionActive}` : `${styles.navigatorOption} `}`}>
                    <div className={styles.navigatorOptionIcon}>
                        <i className= "fi fi-rr-building" ></i>
                    </div>
                    <div className={styles.navigatorOptionName}>
                        Organization
                    </div>
                </Link>
                <Link href={"/app/admin"} className={`${isActive("/app/admin") ? `${styles.navigatorOptionActive}` : `${styles.navigatorOption} `}`}>
                    <div className={styles.navigatorOptionIcon}>
                        <i className= "fi fi-rr-admin" ></i>
                    </div>
                    <div className={styles.navigatorOptionName}>
                        Admin
                    </div>
                </Link>
                <Link href={"/app/ticket"} className={`${isActive("/app/ticket") ? `${styles.navigatorOptionActive}` : `${styles.navigatorOption} `}`}>
                    <div className={styles.navigatorOptionIcon}>
                        <i className= "fi fi-rr-ticket" ></i>
                    </div>
                    <div className={styles.navigatorOptionName}>
                        Tickets
                    </div>
                </Link>
                <Link href={"/app/forums"} className={`${isActive("/app/forums") ? `${styles.navigatorOptionActive}` : `${styles.navigatorOption} `}`}>
                    <div className={styles.navigatorOptionIcon}>
                        <i className= "fi fi-rr-users-alt" ></i>
                    </div>
                    <div className={styles.navigatorOptionName}>
                        Forums
                    </div>
                </Link>
                <div onClick={()=> handleWalletDisconnect()} className={styles.navigatorOption}>
                    <div className={styles.navigatorOptionIcon}>
                        <i className= "fi fi-rr-exit" ></i>
                    </div>
                    <div className={styles.navigatorOptionName}>
                        Logout
                    </div>
                </div>
                
            </div>
        </div>
    </>)
}