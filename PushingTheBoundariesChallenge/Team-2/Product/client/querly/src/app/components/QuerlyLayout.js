"use client"

import React,{useState,useEffect} from "react";
import styles from "./style/Querly.module.css";
import QuerlyAuth from "./auth/QuerlyAuth";
import { useAccount } from "wagmi";
import PushStore from "../config/store/PushStore";
import { useRecoilValue } from "recoil";
import QuerlyBotInterface from "./querlybot/QuerlyBotInterface";

export default function QuerlyLayout(){

    const [interfaceOpen,setInterfaceOpen] = useState(false);
    const {isConnected} = useAccount();
    const pushUser = useRecoilValue(PushStore.pushUser);
    
    const handleInterfaceOpen = () => {
        setInterfaceOpen(!interfaceOpen);
    }

    return(<>
        <div className={styles.querlyLayout}>
            <div className={styles.querlyContainer}>
                {interfaceOpen &&
                    <div className={styles.querlyInterface}>
                        {(!isConnected || pushUser.initializedUser===null ) &&
                            <QuerlyAuth />
                        }
                        {(isConnected && pushUser.initializedUser!==null ) &&
                            <>
                                <QuerlyBotInterface />
                            </>
                        }
                        
                    </div>
                }
                <div className={styles.querlyIcon} onClick={() => handleInterfaceOpen()}>
                    <svg width="50" height="50" viewBox="0 0 400 400" fill="none" xmlns="http://www.w3.org/2000/svg">
                        <rect width="400" height="400" rx="200" fill="#27273E"/>
                        <path className={styles.qurlyIconRotate} d="M200.005 350C190.021 350 180.623 346.107 173.556 339.032L146.67 312.117H125.219C104.603 312.117 87.8263 295.322 87.8263 274.684V253.21L60.9283 226.283C46.3576 211.684 46.3576 187.951 60.9283 173.352L87.8263 146.425V124.951C87.8263 104.313 104.603 87.5175 125.219 87.5175H146.67L173.568 60.603C187.69 46.4657 212.32 46.4657 226.454 60.603L253.34 87.5175H274.791C295.407 87.5175 312.184 104.313 312.184 124.951V146.425L339.081 173.352C353.64 187.951 353.64 211.684 339.081 226.283L312.184 253.21V274.684C312.184 295.322 295.407 312.117 274.791 312.117H253.34L226.442 339.032C219.387 346.094 209.989 350 200.005 350Z" fill="white"/>
                        <path  d="M183.562 249.936C183.562 259.078 190.982 266.498 200.125 266.498C209.267 266.498 216.687 259.078 216.687 249.936C216.687 240.793 209.267 233.373 200.125 233.373C190.982 233.373 183.562 240.793 183.562 249.936Z" fill="#27273E"/>
                        <path d="M211.167 205.824C211.167 202.368 214.026 197.289 216.102 196.152L216.091 196.163C228.502 189.306 235.182 175.272 232.72 161.227C230.368 147.844 219.382 136.869 206.032 134.539C196.26 132.762 186.345 135.434 178.837 141.749C171.317 148.065 167 157.318 167 167.134C167 173.24 171.947 178.176 178.042 178.176C184.137 178.176 189.083 173.24 189.083 167.134C189.083 163.855 190.519 160.763 193.036 158.665C195.576 156.512 198.844 155.651 202.223 156.28C206.54 157.031 210.217 160.708 210.979 165.036C212.006 170.899 208.638 175.051 205.436 176.807C196.117 181.941 189.083 194.418 189.083 205.824V211.29C189.083 217.396 194.03 222.332 200.125 222.332C206.22 222.332 211.167 217.396 211.167 211.29V205.824Z" fill="#27273E"/>
                    </svg>
                </div>
            </div>
            
        </div>
    </>)
}