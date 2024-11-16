"""
Created on Fri Aug  9 00:37:56 2024

@author: ANAND
"""

import sys
import json
import numpy as np
import control as ct

# KS is btwn 1 and 20

def LQRchargecurve(DepTime, EAmount, KS):
    # system matrices
    A=np.array([[0]])
    B=np.array([[1]])
    C=np.array([[1]])
    D=np.array([[0]])
     
    #define the initial condition
    x0=np.array([[0]])
   
    # define the time vector for simulation
    startTime=0
    endTime = round(DepTime/60)*60
    numberSamples = round(endTime/60)
    timeVector=np.linspace(startTime,endTime,numberSamples)
    #print('TimeVector!: ', timeVector)
   
    # state weighting matrix
    Q=KS/1000
     
    # input weighting matrix
    R=KS*1000

    # system matrices

    sysStateSpace=ct.ss(A,B,C,D)
    xd=np.array([[EAmount]])

    K, S, E = ct.lqr(sysStateSpace, Q, R)

    Acl=A-np.matmul(B,K)
    Bcl=-Acl
     
    # define the state-space model
    sysStateSpaceCl=ct.ss(Acl,Bcl,C,D)
     
    # define the input for closed-loop simulation
    inputCL=np.zeros(shape=(1,numberSamples))
    inputCL[0,:]=xd*np.ones(numberSamples)
    returnSimulationCL = ct.forced_response(sysStateSpaceCl,
                                          timeVector,
                                          inputCL,
                                          x0)
   

    # YC is state of charge of the vehicle (progress to eamount)
    # UC is power
    # TC is the timevector 
    Yc = returnSimulationCL.states[0,:]
    Uc=  np.transpose(-K*(returnSimulationCL.states[0,:]-inputCL))
    Tc = returnSimulationCL.time

    return Yc, Uc, Tc


def cleanData(yc, uc, tc):
    yc_curve = [{"x": float(x), "y": float(y)} for x, y in zip(yc, tc)]
    uc_curve = [{"x": float(y), "y": float(x)} for x, y in zip(uc, tc)]
    return {
      "series": ["A", "B"],
      "data": [yc_curve, uc_curve],
      "labels": ["r1", "r2"]
    }



def main():
    if len(sys.argv) != 4:
        print("Usage: python preview.py <date_time> <deamount> <ks>")
        return
    departure_time = int(sys.argv[1])
    eamount = int(sys.argv[2])
    ks = int(sys.argv[3])
    yc, uc, tc = LQRchargecurve(departure_time, eamount, ks)
    return_obj = cleanData(yc, uc, tc)
    print(json.dumps(return_obj))

if __name__ == "__main__":
    main()






