"use client"

import React, { useEffect, useState } from 'react';
import { useGetAllInvitations,useAcceptInvitation } from '@/app/config/contracts/admins/AdminManger';
import styles from "./styles/Admin.module.css";
import { useAccount } from 'wagmi';

export default function AdminPage(){
    const {address} = useAccount();
    const [invitations, setInvitations] = useState([]);
    const { invitations: allInvitations, isLoading, error } = useGetAllInvitations(address); 

    console.log(allInvitations)

    useEffect(() => {
        if (allInvitations) {
        setInvitations(allInvitations); 
        }
    }, [allInvitations]);

    const { acceptInvitation } = useAcceptInvitation(); 

    const handleAcceptInvitation = (subscriberAddress) => {
        acceptInvitation(subscriberAddress)
        .then(() => {
            
            setInvitations(invitations.filter(addr => addr !== subscriberAddress));
        })
        .catch((error) => {
            console.error('Error accepting invitation:', error);
        });
    };

    return(<>
<div className={styles.adminInvitations}>
      <h2>Invitations Received</h2>
     
      {!isLoading && !error && (
        <>
          <ul className={styles.invitationsList}>
            {invitations.map((subscriberAddress) => (
              <li key={subscriberAddress} className={styles.invitationItem}>
                <div className={styles.invitationDetails}>
                  <span>From: {subscriberAddress}</span>
                </div>
                <div className={styles.invitationActions}>
                  <button onClick={() => handleAcceptInvitation(subscriberAddress)}>
                    Accept Invitation
                  </button>
                </div>
              </li>
            ))}
          </ul>
          {invitations.length === 0 && (
            <p>No pending invitations</p>
          )}
        </>
      )}
    </div>
    </>)
}