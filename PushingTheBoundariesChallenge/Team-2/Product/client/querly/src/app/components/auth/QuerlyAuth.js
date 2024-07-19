"use client"

import { useAccount } from "wagmi"
import Button from "../button/Button";
import { ConnectKitButton } from "connectkit";
import LoaderBlackSmall from "../loaders/loaderBlackSmall";
import LoaderWhiteSmall from "../loaders/loaderWhiteSmall";
import styles from "./styles/Auth.module.css";
import PushStore from "@/app/config/store/PushStore";
import { useRecoilValue } from "recoil";
import InitializePush from "./InitializePush";

export default function QuerlyAuth(){
    const { isConnected, address,isDisconnected,status } = useAccount();
    const pushUser = useRecoilValue(PushStore.pushUser);
    const { handleConnect,isLoading:pushInitializing } = InitializePush();
    

    return(<>
        <div className={styles.querlyAuthContainer}>
            <div className={styles.details}>
                <div className={styles.title}>
                    {!isConnected &&
                        <p>
                            Connect
                        </p>
                    }   
                    {isConnected && pushUser.initializedUser===null && 
                        <p>
                            Push
                        </p>
                    }
                </div>
                <div className={styles.description}>
                    {!isConnected &&
                        <p>
                            your web3 wallet to proceed
                        </p>
                    }
                    {isConnected && pushUser.initializedUser===null && 
                        <p>
                            The communication layer for Querly
                        </p>
                    }
                </div>
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
                {isConnected &&  pushUser.initializedUser===null && 
                    <Button buttonName={"Initialize"} isLoading={pushInitializing} buttonFunction = {()=> handleConnect()} buttonWidth={"60%"}/>
                }
            </div>
        </div>
    </>)
}