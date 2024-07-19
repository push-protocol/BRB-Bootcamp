"use client"

import React, { useEffect, useState } from "react";
import styles from "./styles/Organization.module.css";
import { useBalanceOf, useAllowance, useApprove } from "@/app/config/contracts/ERC20/Token";
import { useAccount } from "wagmi";
import Button from "@/app/components/button/Button";
import { contractSubscription } from "@/lib/secure/Config";
import { useIsSubscribed,useSubscribe,useGetSubscriptionEnd } from "@/app/config/contracts/subscription/Subscription";
import { useInviteAdmin,useGetAllAdmins } from "@/app/config/contracts/admins/AdminManger";
import { useRemoveAdmin } from "@/app/config/contracts/admins/AdminManger";
import { useChatStream } from "@/app/config/push/ChatStreamInitializer";

export default function OrganizationPage() {
    const { address } = useAccount();
    const { balance, isLoading: isBalanceLoading } = useBalanceOf(address);
    const { allowance, error, isLoading: isAllowanceLoading } = useAllowance(address, contractSubscription);
    const { approve, isPending: isApprovePending, data: approveData } = useApprove();
    const { subscribe, isPending: isSubscribePending, data: subscribeData } = useSubscribe();
    const { isSubscribed } = useIsSubscribed(address);
    const { subscriptionEnd } = useGetSubscriptionEnd(address);
  
    function unixToDate(unixTimestamp) {
      const date = new Date(unixTimestamp * 1000);
      return date.toLocaleDateString();
    }
    const SubscriptionEndDate = unixToDate(Number(subscriptionEnd));
  
    const handleSubscription = async () => {
      const requiredAmount = 100n * 1000000000000000000n;
      if (allowance < requiredAmount) {
        try {
          await approve(contractSubscription, "100");
          await subscribe();
        } catch (error) {
          console.error("Error approving tokens:", error);
        }
      } else {
        await subscribe();
      }
    };
  
    // Admins
    const [adminAddress, setAdminAddress] = useState('');
    const { inviteAdmin, isPending: isInviting } = useInviteAdmin();
    const { admins, isLoading, error: adminError } = useGetAllAdmins(address);
    const { removeAdmin, isPending: isRemoving } = useRemoveAdmin();
  
    const handleInviteAdmin = (e) => {
      e.preventDefault();
      inviteAdmin(adminAddress);
      setAdminAddress('');
    };
  
    const handleRemoveAdmin = async (adminAddress) => {
      try {
        await removeAdmin(adminAddress);
      } catch (error) {
        console.error("Error removing admin:", error);
      }
    };
  
    // Datastore inputs
    const [dataRoute, setDataRoute] = useState('');
    const [dataValue, setDataValue] = useState('');
    const {stream, isStreamConnected, isStreamInitialized, pushUser, setPushUser} = useChatStream();

    

    const handleStoreData = async() => {
        const jsonData = {
            subscriber: address,
            route: dataRoute,
            type: "store",
            info: dataValue
          };
        const jsonString = JSON.stringify(jsonData);
        const recipient = "0x8Df568a58A73356637e3ee1A86d1f089299B0D6B"
        await pushUser.chat.send(recipient, {
            type: 'Text',
            content: jsonString,
        });
    };
  
    return (
      <div className={styles.orgPage}>
        <div className={styles.MainContainer}>
          <div className={styles.MainContainerLeft}>
            {!isSubscribed && (
              <p>
                <span>You Can Subscribe to Querly with Just</span>
                <span>100 $TOKENS / month</span>
              </p>
            )}
            {isSubscribed && (
              <p>
                <span>You're subscribed!</span>
                <span>Enjoy Querly!</span>
              </p>
            )}
          </div>
          <div className={styles.MainContainerRight}>
            {!isSubscribed && (
              <Button
                buttonWidth={"50%"}
                buttonName={"Subscribe"}
                buttonFunction={() => handleSubscription()}
                isLoading={isApprovePending || isSubscribePending}
              />
            )}
            {isSubscribed && <>End Date: {SubscriptionEndDate}</>}
          </div>
        </div>
  
        {isSubscribed && (
          <>
            <div className={styles.adminContainer}>
              <form onSubmit={handleInviteAdmin} className={styles.inputContainer}>
                <input
                  type="text"
                  placeholder="Admin address"
                  value={adminAddress}
                  onChange={(e) => setAdminAddress(e.target.value)}
                  className={styles.inputField}
                />
                <button type="submit" className={styles.submitButton} disabled={isInviting}>
                  {isInviting ? 'Inviting...' : 'Invite Admin'}
                </button>
              </form>
  
              <ul className={styles.adminList}>
                {isLoading && <li>Loading admins...</li>}
                {adminError && <li>Error loading admins: {adminError.message}</li>}
                {admins && admins.length === 0 && <li>No admins found.</li>}
                {admins &&
                  admins.map((admin, index) => (
                    <li key={index} className={styles.adminItem}>
                      {admin}
                      <Button
                        buttonWidth={"auto"}
                        buttonName={"Remove"}
                        buttonFunction={() => handleRemoveAdmin(admin)}
                        isLoading={isRemoving}
                        className={styles.removeButton}
                      />
                    </li>
                  ))}
              </ul>
  
              {/* Datastore container */}
              <div className={styles.datastoreContainer}>
                <form onSubmit={(e) => e.preventDefault()} className={styles.inputContainer}>
                  <input
                    type="text"
                    placeholder="Data Route"
                    value={dataRoute}
                    onChange={(e) => setDataRoute(e.target.value)}
                    className={styles.inputField}
                  />
                  <textarea
                    placeholder="Data"
                    value={dataValue}
                    onChange={(e) => setDataValue(e.target.value)}
                    className={styles.textareaField}
                  />
                  <button type="button" className={styles.submitButton} onClick={()=> handleStoreData()}>
                    Store Data
                  </button>
                </form>
              </div>
            </div>
          </>
        )}
      </div>
    );
  }