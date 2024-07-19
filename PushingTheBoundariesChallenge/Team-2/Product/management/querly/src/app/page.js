"use client"

import React from "react";
import styles from "./styles/Page.module.css";
import QuerlyLogoTag from "@/../public/assets/svg/QuerlyLogoTag.svg";
import Link from "next/link";

export default function Home() {
  return (
    <>
      <div className={styles.homePage}>
          <div className={styles.homePageContainer}>
            <div className={styles.homePageHeader}>
              <div className={styles.homePageHeaderLeft}>
                <QuerlyLogoTag />
              </div>
              <div className={styles.homePageHeaderCenter}>
                <div className={styles.homePageHeaderCenterOptions}>
                  <div className={styles.homePageHeaderCenterOption}>
                    <p>
                      Product
                    </p>
                  </div>
                  <div className={styles.homePageHeaderCenterOption}>
                    <p>
                      Subscription
                    </p>
                  </div>
                  <div className={styles.homePageHeaderCenterOption}>
                    <p>
                      Integration
                    </p>
                  </div>
                  <div className={styles.homePageHeaderCenterOption}>
                    <p>
                      Resource
                    </p>
                  </div>
                </div>
              </div>
              <div className={styles.homePageHeaderRight}>
                  <Link href={"/auth"} className={styles.homePageHeaderRightOption}>
                    <p>
                      Authenticate
                    </p>
                  </Link>
              </div>
            </div> 
            <div className={styles.homePageContent}>
              <div className={styles.homePageContentMain}>
                <p>
                Future of customer support powered by <span className={styles.homePageContentMainAiDriven}>Web3 and AI.</span>
                </p>
              </div>
              <div className={styles.homePageContentSub}>
                <p>
                  Push Chats integration streamlines our bot and live support.
                </p>
              </div>
            </div>
          </div> 
      </div> 
    </>
  );
}
