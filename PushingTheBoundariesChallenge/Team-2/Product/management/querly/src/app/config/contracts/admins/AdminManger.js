"use client"

import { 
  useReadContract,
  useWriteContract,
} from 'wagmi';
import abi from "./abi/abi";
import { contractAdmins, skaleChainId } from '@/lib/secure/Config';

const CONTRACT_ADDRESS = contractAdmins;
const CHAIN_ID = skaleChainId;

export const useInviteAdmin = () => {
  const { writeContract, isPending, data } = useWriteContract();
  const inviteAdmin = async (adminAddress) => {
    try {
      writeContract({
        address: CONTRACT_ADDRESS,
        abi: abi,
        functionName: 'inviteAdmin',
        args: [adminAddress],
        chainId: CHAIN_ID,
      });
    } catch (error) {
      console.error("Error inviting admin:", error);
    }
  };
  return { inviteAdmin, isPending, data };
};

export const useAcceptInvitation = () => {
  const { writeContract, isPending, data } = useWriteContract();
  const acceptInvitation = async (subscriberAddress) => {
    try {
      writeContract({
        address: CONTRACT_ADDRESS,
        abi: abi,
        functionName: 'acceptInvitation',
        args: [subscriberAddress],
        chainId: CHAIN_ID,
      });
    } catch (error) {
      console.error("Error accepting invitation:", error);
    }
  };
  return { acceptInvitation, isPending, data };
};

export const useRemoveSelfAsAdmin = () => {
  const { writeContract, isPending, data } = useWriteContract();
  const removeSelfAsAdmin = async () => {
    try {
      writeContract({
        address: CONTRACT_ADDRESS,
        abi: abi,
        functionName: 'removeSelfAsAdmin',
        chainId: CHAIN_ID,
      });
    } catch (error) {
      console.error("Error removing self as admin:", error);
    }
  };
  return { removeSelfAsAdmin, isPending, data };
};

export const useRemoveAdmin = () => {
  const { writeContract, isPending, data } = useWriteContract();
  const removeAdmin = async (adminAddress) => {
    try {
      writeContract({
        address: CONTRACT_ADDRESS,
        abi: abi,
        functionName: 'removeAdmin',
        args: [adminAddress],
        chainId: CHAIN_ID,
      });
    } catch (error) {
      console.error("Error removing admin:", error);
    }
  };
  return { removeAdmin, isPending, data };
};

export const useGetAllAdmins = (callerAddress) => {
  const { data, error, isLoading } = useReadContract({
    address: CONTRACT_ADDRESS,
    abi: abi,
    functionName: 'getAllAdmins',
    args: [callerAddress], // Pass caller address or relevant context here
    chainId: CHAIN_ID,
  });
  return { admins: data, error, isLoading };
};

export const useIsAdmin = (subscriberAddress, adminAddress) => {
  const { data, error, isLoading } = useReadContract({
    address: CONTRACT_ADDRESS,
    abi: abi,
    functionName: 'isAdmin',
    args: [subscriberAddress, adminAddress],
    chainId: CHAIN_ID,
  });
  return { isAdmin: data, error, isLoading };
};

export const useGetAdminSubscriber = (adminAddress) => {
  const { data, error, isLoading } = useReadContract({
    address: CONTRACT_ADDRESS,
    abi: abi,
    functionName: 'getAdminSubscriber',
    args: [adminAddress],
    chainId: CHAIN_ID,
  });
  return { subscriberAddress: data, error, isLoading };
};

export const useAdminToSubscriber = (adminAddress) => {
  const { data, error, isLoading } = useReadContract({
    address: CONTRACT_ADDRESS,
    abi: abi,
    functionName: 'adminToSubscriber',
    args: [adminAddress],
    chainId: CHAIN_ID,
  });
  return { subscriberAddress: data, error, isLoading };
};

export const useSubscriberToPendingAdmin = (subscriberAddress, adminAddress) => {
  const { data, error, isLoading } = useReadContract({
    address: CONTRACT_ADDRESS,
    abi: abi,
    functionName: 'subscriberToPendingAdmin',
    args: [subscriberAddress, adminAddress],
    chainId: CHAIN_ID,
  });
  return { isPending: data, error, isLoading };
};


export const useGetAllInvitations = (adminAddress) => {
  const { data, error, isLoading } = useReadContract({
    address: CONTRACT_ADDRESS,
    abi: abi,
    functionName: 'getAllInvitations',
    args: [adminAddress],
    chainId: CHAIN_ID,
  });
  return { invitations: data, error, isLoading };
};

export const useSubscriptionContract = () => {
  const { data, error, isLoading } = useReadContract({
    address: CONTRACT_ADDRESS,
    abi: abi,
    functionName: 'subscriptionContract',
    chainId: CHAIN_ID,
  });
  return { subscriptionContractAddress: data, error, isLoading };
};