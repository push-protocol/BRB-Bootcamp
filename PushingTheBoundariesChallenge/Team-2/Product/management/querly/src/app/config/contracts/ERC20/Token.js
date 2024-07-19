"use client"

import { 
  useReadContract,
  useWriteContract,
  useWaitForTransaction
} from 'wagmi';
import { parseEther } from 'viem';
import abi from "./abi/abi";
import { contractERC20 } from '@/lib/secure/Config';

const TOKEN_ADDRESS = contractERC20;

export const useApprove = () => {
  const { writeContract, isPending, data } = useWriteContract();

  const approve = async (spender, amount) => {
    try {
      writeContract({
        address: TOKEN_ADDRESS,
        abi: abi,
        functionName: 'approve',
        args: [spender, parseEther(amount)],
      });
    } catch (error) {
      console.error("Error approving tokens:", error);
    }
  };

  return { approve, isPending, data };
};

export const useMint = () => {
  const { writeContract, isPending, data } = useWriteContract();

  const mint = async (to, amount) => {
    try {
      writeContract({
        address: TOKEN_ADDRESS,
        abi: abi,
        functionName: 'mint',
        args: [to, parseEther(amount)],
      });
    } catch (error) {
      console.error("Error minting tokens:", error);
    }
  };

  return { mint, isPending, data };
};

export const usePermit = () => {
  const { writeContract, isPending, data } = useWriteContract();

  const permit = async (owner, spender, value, deadline, v, r, s) => {
    try {
      writeContract({
        address: TOKEN_ADDRESS,
        abi: abi,
        functionName: 'permit',
        args: [owner, spender, value, deadline, v, r, s],
      });
    } catch (error) {
      console.error("Error permitting tokens:", error);
    }
  };

  return { permit, isPending, data };
};

export const useTransfer = () => {
  const { writeContract, isPending, data } = useWriteContract();

  const transfer = async (to, amount) => {
    try {
      writeContract({
        address: TOKEN_ADDRESS,
        abi: abi,
        functionName: 'transfer',
        args: [to, parseEther(amount)],
      });
    } catch (error) {
      console.error("Error transferring tokens:", error);
    }
  };

  return { transfer, isPending, data };
};

export const useTransferFrom = () => {
  const { writeContract, isPending, data } = useWriteContract();

  const transferFrom = async (from, to, amount) => {
    try {
      writeContract({
        address: TOKEN_ADDRESS,
        abi: abi,
        functionName: 'transferFrom',
        args: [from, to, parseEther(amount)],
      });
    } catch (error) {
      console.error("Error transferring tokens from:", error);
    }
  };

  return { transferFrom, isPending, data };
};

export const useTransferOwnership = () => {
  const { writeContract, isPending, data } = useWriteContract();

  const transferOwnership = async (newOwner) => {
    try {
      writeContract({
        address: TOKEN_ADDRESS,
        abi: abi,
        functionName: 'transferOwnership',
        args: [newOwner],
      });
    } catch (error) {
      console.error("Error transferring ownership:", error);
    }
  };

  return { transferOwnership, isPending, data };
};

export const useAllowance = (owner, spender) => {
  const { data, error, isLoading } = useReadContract({
    address: TOKEN_ADDRESS,
    abi: abi,
    functionName: 'allowance',
    args: [owner, spender],
  });

  return { allowance: data, error, isLoading };
};

export const useBalanceOf = (account) => {
  const { data, error, isLoading } = useReadContract({
    address: TOKEN_ADDRESS,
    abi: abi,
    functionName: 'balanceOf',
    args: [account],
  });

  return { balance: data, error, isLoading };
};