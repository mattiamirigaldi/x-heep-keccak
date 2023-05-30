from math import log
import os

QINV=-3327
KYBER_Q= 3329
    
PQCLEAN_KYBER768_CLEAN_zetas = [
    -1044,  -758,  -359, -1517,  1493,  1422,   287,   202,
    -171,   622,  1577,   182,   962, -1202, -1474,  1468,
    573, -1325,   264,   383,  -829,  1458, -1602,  -130,
    -681,  1017,   732,   608, -1542,   411,  -205, -1571,
    1223,   652,  -552,  1015, -1293,  1491,  -282, -1544,
    516,    -8,  -320,  -666, -1618, -1162,   126,  1469,
    -853,   -90,  -271,   830,   107, -1421,  -247,  -951,
    -398,   961, -1508,  -725,   448, -1065,   677, -1275,
    -1103,   430,   555,   843, -1251,   871,  1550,   105,
    422,   587,   177,  -235,  -291,  -460,  1574,  1653,
    -246,   778,  1159,  -147,  -777,  1483,  -602,  1119,
    -1590,   644,  -872,   349,   418,   329,  -156,   -75,
    817,  1097,   603,   610,  1322, -1285, -1465,   384,
    -1215,  -136,  1218, -1335,  -874,   220, -1187, -1659,
    -1185, -1530, -1278,   794, -1510,  -854,  -870,   478,
    -108,  -308,   996,   991,   958, -1460,  1522,  1628
]

##--------------------------------------------------------------------------------------
#----------------HELP FUNCTIONS --------------------------------------------------------
##--------------------------------------------------------------------------------------

def twos_comp(val, bits):
    #this is needed in python to consider the hexadecimal values
    #and consider their negative value: not needed in VHDL,
    #since we designed the HW to work with signed values
    """compute the 2's complement of int value val"""
    if (val & (1 << (bits - 1))) != 0: # if sign bit is set e.g., 8bit: 128-255
        val = val - (1 << bits)        # compute negative value
    return val                         # return positive value as is

def montgomery(a, b):
    
    fmul = a*b
    
    temp = fmul & 0xFFFF
    t = (temp * QINV) &  0xFFFF  
    t_cast_2s = twos_comp(t, 16) #in HW, we already work with signed
    temp1 = t_cast_2s * KYBER_Q
    t = (fmul - temp1) >> 16
    
    return t

def barrett(a):
    q = 3329
    v = ((1 << 26) + q // 2) // q
    
    temp = ((v * a  + (1 << 25)) >> 26)*q
    result = a - temp
    return result

##--------------------------------------------------------------------------------------
#----------------NTT & INTT-------------------------------------------------------------
##--------------------------------------------------------------------------------------

def NTT(A):
    N = len(A)
    B = [_ for _ in A] 
    k=1
    lena = (N//2)

    v = int(log(lena,2))
    m = N//PE

    while lena >= 2:
        start = 0
        while start < N:
            zeta= PQCLEAN_KYBER768_CLEAN_zetas[k]
            k = k+1
            j = start
            while(j < (start + lena)):
                
                t = montgomery(zeta, B[j+lena])
                ADD = (B[j] + t) #ADD
                SUB = (B[j] - t) #SUB
                B[j+lena] = (B[j] - t)
                B[j     ] = (B[j] + t)
                
                #print("NTT: Having zeta=", zeta, "with bt1: ", B[j], "and bt2: ", B[j+lena], "-------> t", t ,"e:" , ADD, " and o: ", SUB)
            
                j = j+1
            start = j + lena
        lena = (lena//2)

    for i in range(N):
        B[i] = barrett(B[i])
        #print("NTT FINAL RESULT-------> r[",i, "]: ",B[i])
        
    return B

def INTT(A):
    N = len(A)
    B = [_ for _ in A]
    k = 127
    lena = 2
    v = int(log(N//2,2))
    m = N//PE

    while lena <= (N//2):
        start = 0
        while start < N:
            zeta= PQCLEAN_KYBER768_CLEAN_zetas[k]
            k -= 1
            j = start
            while(j < (start + lena)):
                t = B[j]

                ADD = B[j+lena] + t
                SUB = B[j+lena] - t
                E=barrett(ADD)
                O=montgomery(zeta, SUB)
                
                #print("INTT Having zeta=", zeta, "with bt1: ", B[j], "and bt2: ", B[j+lena], "-------> e:" , E, " and o: ", O)
                
                B[j] = E
                B[j+lena] = O
                                    
                j = j+1
            start = j + lena
        lena = 2*lena

    for i in range(N):
        B[i] = montgomery(B[i], 1441)
        #print("INTT FINAL RESULT-------> r[",i, "]: ",B[i])
    return B


def PWM(A,B):
    N = len(A)
    k = 127
    lena = 2
    v = int(log(N//2,2))
    m = N//PE
    AB_pwm = []
    even_odd = 1
    
    for i in range(N//2):
        a0 = A[2*i]
        a1 = A[2*i+1]
        b0 = B[2*i]
        b1 = B[2*i+1]
        if even_odd == 1: #use LSB of the counter 
            zeta1 = PQCLEAN_KYBER768_CLEAN_zetas[64+i//2]
            even_odd = 0
            res1 = montgomery(a1,b0)
            res2 = montgomery(a1,b1)
            res3= montgomery(a0,b0)
            res4= montgomery(a0,b1)
            res5 = montgomery(res2, zeta1)
            E2 = res4 + res1
            E1= res5 +res3
            #print("Having zeta=", zeta2, "with a0 , a1: ", a0, ",", a1, "and b0 , b1: ", b0, ",", b1, "-------> r1:" , res1, ", r2:" , res2,", r3:" , res3,", r4:" , res4,", r5:" , res5) 
            #print(" E2=", E2, "E1=", E1)
        else:
            zeta2 = -PQCLEAN_KYBER768_CLEAN_zetas[64+i//2]
            even_odd = 1
            res1 = montgomery(a1,b0)
            res2 = montgomery(a1,b1)
            res3= montgomery(a0,b0)
            res4= montgomery(a0,b1)
            res5 = montgomery(res2, zeta2)
            E2 = res4 + res1
            E1= res5 + res3
            #print("Having zeta=", zeta2, "with a0 , a1: ", a0, ",", a1, "and b0 , b1: ", b0, ",", b1, "-------> r1:" , res1, ", r2:" , res2,", r3:" , res3,", r4:" , res4,", r5:" , res5) 
            #print(" E2=", E2, "E1=", E1)
        AB_pwm.append(E1)
        AB_pwm.append(E2)
        

    return AB_pwm




#---------------------------------------------------------------------------------------
#--------------MAIN---------------------------------------------------------------------
#---------------------------------------------------------------------------------------
FILE_NAME = 'text/'
c_directory = os.getcwd()
f_directory = os.path.join(c_directory, FILE_NAME)
if not os.path.exists(f_directory):
    os.makedirs(f_directory)

# ----------------------------------------------------------
KYBER_REF_NTT = open(FILE_NAME+"/NTT_LOG.txt","w")
KYBER_REF_INTT = open(FILE_NAME+"/INTT_LOG.txt","w")
KYBER_REF_PWM = open(FILE_NAME+"/PWM_LOG.txt","w")
# ---------------------------------------------------------
PE = 2
# ----------------------------------------------------------
n = 256
q = 3329
w = 17
wv= 1175
nv= 3303 # 128^-1 mod 3329 (wont use)
#-----------------------------------------------------------
A_ntt_in = []
A_intt_in = []    
A_ntt_out = []
A_intt_out = []

A_pwm_in = []
B_pwm_in = []
AB_pwm_out = []

REF_ntt = []
REF_intt = []
REF_pwm = []
#----------------------------------------------------------- 
#ACQUISITION using readlines()
file1_ntt = open(FILE_NAME+"/ntt_test/ntt_DIN1.txt","r")
Lines1_ntt = file1_ntt.readlines()
file1_intt = open(FILE_NAME+"/intt_test/intt_DIN1.txt","r")
Lines1_intt = file1_intt.readlines()

file1_pwm = open(FILE_NAME+"/pwm_test/pwm_DIN_A1.txt","r")
Lines1_pwm = file1_pwm.readlines()
file2_pwm = open(FILE_NAME+"/pwm_test/pwm_DIN_B1.txt","r")
Lines2_pwm = file2_pwm.readlines()

for line1_ntt, line1_intt, line1_pwm, line2_pwm in zip(Lines1_ntt, Lines1_intt, Lines1_pwm, Lines2_pwm):
    str_ntt = line1_ntt.strip()
    str_intt = line1_intt.strip()
    str_pwm1 = line1_pwm.strip()
    str_pwm2 = line2_pwm.strip()
    
    A_ntt_in.append(twos_comp(int(line1_ntt.strip(), 16),16))
    A_intt_in.append(twos_comp(int(line1_intt.strip(), 16),16))
    A_pwm_in.append(twos_comp(int(line1_pwm.strip(), 16),16))
    B_pwm_in.append(twos_comp(int(line2_pwm.strip(), 16),16))
    
#APPLICATION
A_ntt_out = NTT(A_ntt_in)
A_intt_out = INTT(A_intt_in)
AB_pwm_out = PWM(A_pwm_in, B_pwm_in)

#CONTROL using readline()
file2_ntt = open(FILE_NAME+"/ntt_test/ntt_DOUT1_INT.txt","r")
Lines2_ntt = file2_ntt.readlines()
file2_intt = open(FILE_NAME+"/intt_test/intt_DOUT1_INT.txt","r")
Lines2_intt = file2_intt.readlines()
file3_pwm = open(FILE_NAME+"/pwm_test/pwm_DOUT1_INT.txt","r")
Lines3_pwm = file3_pwm.readlines()

for line2_ntt, line2_intt, lines3_pwm in zip(Lines2_ntt, Lines2_intt, Lines3_pwm):
    REF_ntt.append(line2_ntt.strip())
    REF_intt.append(line2_intt.strip())
    REF_pwm.append(lines3_pwm.strip())
    

error_ntt=0

for a_ntt_in,a_ntt_out, ref_ntt in zip(A_ntt_in,A_ntt_out, REF_ntt):
    if a_ntt_out != int(ref_ntt):
        KYBER_REF_NTT.write("Obtained: " + hex(a_ntt_out).replace("L","")[2:] + ", reference: " + ref_ntt + "\n")
        print("NTT: Obtained: " , a_ntt_out, ", reference: " , ref_ntt)
        error_ntt+=1

if error_ntt==0:
    print("*******************************\nNTT correct!\n*************************************")
    KYBER_REF_NTT.write("NTT correct!")
    
error_intt=0
for a_intt_in,a_intt_out, ref_intt in zip(A_intt_in,A_intt_out, REF_intt):
    if a_intt_out != int(ref_intt):
        KYBER_REF_INTT.write("Obtained: " + hex(a_intt_out).replace("L","")[2:] + ", reference: " + ref_intt + "\n")
        print("INTT: Obtained: " , a_intt_out, ", reference: " , ref_intt)
        error_intt+=1

if error_intt==0:
    print("*************************************\nINTT correct!\n*************************************")
    KYBER_REF_INTT.write("INTT correct!")
    

error_pwm=0
for a_pwm_in, b_pwm_in, ab_pwm_out, ref_pwm in zip(A_pwm_in,B_pwm_in,AB_pwm_out, REF_pwm):
    if ab_pwm_out != int(ref_pwm):
        KYBER_REF_PWM.write("Obtained: " + hex(ab_pwm_out).replace("L","")[2:] + ", reference: " + ref_pwm + "\n")
        print("PWM: Obtained: " , ab_pwm_out, ", reference: " , ref_pwm)
        error_pwm+=1

if error_pwm==0:
    print("*******************************\nPWM correct!\n*************************************")
    KYBER_REF_PWM.write("PWM correct!")