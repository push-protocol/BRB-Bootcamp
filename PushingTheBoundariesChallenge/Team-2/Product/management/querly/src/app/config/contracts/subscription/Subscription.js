"use client"

import { 
  useReadContract,
  useWriteContract,
  useWaitForTransaction
} from 'wagmi';
import { parseEther } from 'viem';
import abi from "./abi/abi";
import { contractSubscription, skaleChainId } from '@/lib/secure/Config';

const CONTRACT_ADDRESS = contractSubscription;
const CHAIN_ID = skaleChainId;

export const useSubscribe = () => {
  const { writeContract, isPending, data } = useWriteContract();

  const subscribe = async () => {
    try {
      writeContract({
        address: CONTRACT_ADDRESS,
        abi: abi,
        functionName: 'subscribe',
        chainId: CHAIN_ID,
      });
    } catch (error) {
      console.error("Error subscribing:", error);
    }
  };

  return { subscribe, isPending, data };
};

export const useIsSubscribed = (userAddress) => {
  const { data, error, isLoading } = useReadContract({
    address: CONTRACT_ADDRESS,
    abi: abi,
    functionName: 'isSubscribed',
    args: [userAddress],
    chainId: CHAIN_ID,
  });

  return { isSubscribed: data, error, isLoading };
};

export const useGetSubscriptionEnd = (userAddress) => {
  const { data, error, isLoading } = useReadContract({
    address: CONTRACT_ADDRESS,
    abi: abi,
    functionName: 'getSubscriptionEnd',
    args: [userAddress],
    chainId: CHAIN_ID,
  });

  return { subscriptionEnd: data, error, isLoading };
};

export const useUpdateSubscriptionFee = () => {
  const { writeContract, isPending, data } = useWriteContract();

  const updateSubscriptionFee = async (newFee) => {
    try {
      writeContract({
        address: CONTRACT_ADDRESS,
        abi: abi,
        functionName: 'updateSubscriptionFee',
        args: [parseEther(newFee)],
        chainId: CHAIN_ID,
      });
    } catch (error) {
      console.error("Error updating subscription fee:", error);
    }
  };

  return { updateSubscriptionFee, isPending, data };
};

export const useUpdateSubscriptionPeriod = () => {
  const { writeContract, isPending, data } = useWriteContract();

  const updateSubscriptionPeriod = async (newPeriod) => {
    try {
      writeContract({
        address: CONTRACT_ADDRESS,
        abi: abi,
        functionName: 'updateSubscriptionPeriod',
        args: [newPeriod],
        chainId: CHAIN_ID,
      });
    } catch (error) {
      console.error("Error updating subscription period:", error);
    }
  };

  return { updateSubscriptionPeriod, isPending, data };
};

export const useWithdrawFees = () => {
  const { writeContract, isPending, data } = useWriteContract();

  const withdrawFees = async (amount) => {
    try {
      writeContract({
        address: CONTRACT_ADDRESS,
        abi: abi,
        functionName: 'withdrawFees',
        args: [parseEther(amount)],
        chainId: CHAIN_ID,
      });
    } catch (error) {
      console.error("Error withdrawing fees:", error);
    }
  };

  return { withdrawFees, isPending, data };
};

export const useGetSubscriptionFee = () => {
  const { data, error, isLoading } = useReadContract({
    address: CONTRACT_ADDRESS,
    abi: abi,
    functionName: 'subscriptionFee',
    chainId: CHAIN_ID,
  });

  return { subscriptionFee: data, error, isLoading };
};

export const useGetSubscriptionPeriod = () => {
  const { data, error, isLoading } = useReadContract({
    address: CONTRACT_ADDRESS,
    abi: abi,
    functionName: 'subscriptionPeriod',
    chainId: CHAIN_ID,
  });

  return { subscriptionPeriod: data, error, isLoading };
};