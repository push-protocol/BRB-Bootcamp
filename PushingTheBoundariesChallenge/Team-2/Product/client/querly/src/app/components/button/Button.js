"use client"

import React from "react";
import LoaderBlackSmall from "../loaders/loaderBlackSmall";
import LoaderWhiteSmall from "../loaders/loaderWhiteSmall";
import styles from "./styles/Button.module.css"

export default function Button({buttonFunction,isLoading,buttonName,isDark = false,buttonWidth}){
    return(<>
        <button onClick={() => buttonFunction()} className={`${styles.button} ${isDark? styles.dark : ''}`} style={{width:`${buttonWidth}`}}>
            {isLoading ? (
                <>
                    {isDark &&
                        <LoaderWhiteSmall />
                    }
                    {!isDark &&
                        <LoaderBlackSmall />
                    }
                </>
            ) : (
            `${buttonName}`
            )}
        </button>
    </>)
}