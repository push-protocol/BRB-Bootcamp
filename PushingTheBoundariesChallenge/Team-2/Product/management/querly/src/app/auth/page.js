"use client"

import React from 'react';
import styles from "./styles/Auth.module.css";
import Button from "../components/button/Button";
import { ConnectKitButton } from "connectkit";
import { useAccount } from "wagmi";
import { useSIWE } from "connectkit";
import RouterPushLink from "../helpers/RouterPushLink";
import videoSrc from '@/../public/assets/videos/auth.mp4';
import PushStore from "../config/store/PushStore";
import { useRecoilValue } from "recoil";
import InitializePush from "./InitializePush";

export default function AuthPage(){
    const { isConnected, address,isDisconnected,status } = useAccount();
    const { isSignedIn, isLoading: siweConnecting, signIn,signOut } = useSIWE();
    const pushUser = useRecoilValue(PushStore.pushUser)
    const {routeTo,isRouterLinkOpening} = RouterPushLink()
    const { handleConnect,isLoading:pushInitializing } = InitializePush();
    

    return(<>
        <div className={styles.auth}>
            <div className={styles.container}>
                
                <div className={styles.details}>
                    <div className={styles.title}>
                        {!isConnected &&
                            <p>
                                Connect
                            </p>
                        }
                         {isConnected && !isSignedIn && 
                            <p>
                                SIWE
                            </p>
                         }
                         {isConnected && isSignedIn && pushUser.initializedUser===null && 
                            <p>
                                Push
                            </p>
                         }
                         {isConnected && isSignedIn && pushUser.initializedUser!==null && 
                            <p>
                                Hurray
                            </p>
                         }
                    </div>
                    <div className={styles.description}>
                        {!isConnected &&
                            <p>
                                your web3 wallet to proceed
                            </p>
                        }
                        {isConnected && !isSignedIn && 
                            <p>
                               Sing In With Ethereum
                            </p>
                         }
                         {isConnected && isSignedIn && pushUser.initializedUser===null && 
                            <p>
                                The communication layer for Querly
                            </p>
                         }
                         {isConnected && isSignedIn && pushUser.initializedUser!==null && 
                            <p>
                                Welcome to Querly, let's get started!
                            </p>
                         }
                    </div>
                    <div className={styles.action}>
                        <ConnectKitButton.Custom>
                            {({ isConnected, isConnecting: accountConnecting, show }) => {
                                return(<>
                                    {!isConnected && show && (
                                        <Button buttonName={"Authenticate"} isLoading={accountConnecting} buttonFunction = {show} buttonWidth={"60%"}/>
                                    )}
                                </>)
                            }}
                        </ConnectKitButton.Custom>
                        {isConnected && !isSignedIn && 
                            <Button buttonName={"Sign In"} isLoading={siweConnecting} buttonFunction = {signIn} buttonWidth={"60%"}/>
                        }
                        {isConnected && isSignedIn && pushUser.initializedUser===null && 
                            <Button buttonName={"Initialize"} isLoading={pushInitializing} buttonFunction = {()=> handleConnect()} buttonWidth={"60%"}/>
                        }
                        {isConnected && isSignedIn && pushUser.initializedUser!==null && 
                            <Button buttonName={"Continue"} isLoading={isRouterLinkOpening} buttonFunction = {() => routeTo("/app")} buttonWidth={"60%"}/>
                        }
                    </div>
                </div>
            </div>
            <div className={styles.graphics}>
                <video className={styles.videoPlayer} src={videoSrc} autoPlay loop muted playsinline> {/**Turn autoplay on deployment */}
                    Your browser does not support the video tag. 
                </video>
            </div>
        </div>
    </>)
}