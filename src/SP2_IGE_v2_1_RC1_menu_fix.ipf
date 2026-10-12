// ============================================================================
// SP2 IGE - BOITE A OUTILS IGE v2.1
// Timed liquid-sample processing and automatic AquaDAG calibration for
// PSI SP2 Toolkit 4.111 / Igor Pro 6.37.
// v2.1: stable on-demand particle properties + four-state standard recovery QC.
//
// Design principles:
//   * PSI particle calibration and post-processing remain unchanged.
//   * One .sp2b file can contain multiple liquid samples/standards.
//   * Each row is defined by FileDate + FileNumList + StartTime + StopTime.
//   * Exact-window concentration is extracted with the native PSI routine
//       SP2_ConcTimeSeriesExtractor(..., IntSec=-1, StartTime=..., EndTime=...).
//   * Liquid concentration uses the native PSI CETAC relationship:
//       C_liquid = C_aerosol * PurgeAirFlow/(LiqSampleFlow-LiqDrainFlow).
//   * AquaDAG efficiency reproduces the current Excel workflow:
//       efficiency = SLOPE(raw liquid concentration, nominal AquaDAG)/AQ_rBC_fraction
//       corrected rBC = raw liquid concentration / efficiency
//   * The OLS intercept and intercept-corrected concentration are retained as
//     diagnostics; the primary reported columns reproduce the Excel method.
// ============================================================================

// Embedded interface banner: user-supplied JPEG, 780x260, RGB, 72 dpi.
Picture IGE_UGA_BC_Banner
	ASCII85Begin
	s4IA0!"_al8O`[\!<E0k!([(is5F)b8OGjP:f:(Y8PDPQ!<E0#!_dE?D0#hF!!$kRFE18L66KB5
	=s+(8!"&]1!#,Dm!$u&`F)XEA:eUihzzzzzzp=93Ezdk,BGD0#[Wzzzzzzzzzzz!"3=KF(51M!=
	/Z*!&e>+Ec_9]!C-Vb!).TYE-)'[!K7!Y!#/pV@:T?<!MBDm!%`.m=]te*!R(ND!#/mE=]te*!T
	3qX!#0'J=]te*!V??l!#0HQ;F:Ea!XJc+!$GoR;F:Ea!XJc+!$G`M;F:Ea!XJc+!$GcbEbtdV![
	n$K!$lDtF^kCOz!!*'"!"<FV<Drkt!#bh;!#tu[!)`ee!($Z.!+GqN!,2FL!-A2m!,2FN!!$kPF
	^kCOz!!*'"!"<FV<Drkt!&+BQ!#tu6!,hi[!+Q"I!,qp`!-/'R!+u:F!-A2l!$D8a!-8-O!$D8R
	!-/'N!+c.H!-q[L=s*eFzp=93Ezdk,WQ1GSq1!!!!"$pjpo"lB:Zo-FA:#Eo,frK.'Zqk=&irLs
	8l"5EkV^i!7W=s*eFzDkI(13;!7O"-?Vf=s*eFz,bG&:%tjo_[_l3M=s*eFz@[@&p[taq`(tik:
	Ea\qJ!!!!$!!!!#AnD#CntuHf%9WZ2'@6^Z$<q"REbtdV!!!!$zUXoJG<-nTF9[*P;R@4*U->!5
	X%p].h!(-_g!WiH*!WrN,!sA]."9f&7"U"r3$3pe?#Rh%K$k!CM$OmRY&.K*]%LWXU((_&k'GV>
	t$kF-k().Su'GV>^gAjSA!sA`1"9f)8"UPkP$Omda'GM5q'GM5q'GM5q'GM5q'GM5q'GM5q'GM5
	q'GM5q'GM5q'GM5q'GM5q'GM5qs1eUH#QY&1$j-MB!!3`5!tbS6_uLkZ!!*6(!<E3%!<<*"z!!*
	-'"9eu7#RLhGs24oF&-)b4!s8T-!sJi2"98E&I/sBO!!El;&g8tq"qsjB#9n.%14bR]#U;[@_%f
	kqn0Bf!Ee4T)()If*)C6^X-n-W&2)[BQ3BBMq77Kd<8P2o\<E<1'=^#<GAS,RgBkh^2F`qtRH$Y
	*rKnbA=M2II[Pa.Q$R$jD;USO``Vl6SpZEppG[^WcW]#)A'`Q#s>ai`&\eCE.%f\,!;ioB+]k3(
	smlLFH:o_%qPq"add_uLk[!!<6&!<E3%!<E3$z!!*-'"9eu7#RLhGs24oF&HDk5!X&W.":#)5"9
	8H(G5qXF!tbY>+Ya065u@kqE>'NOJHurVOeK%r#pV6(n.fDQd0^X71uTbN(Dn#.-7:2j.Q'+C3&
	s#e6q'R884cEP<)lt#=BSg;A7]@cBPD4&FEMbNG^4UeK7nr5LPUeEP*;,qQC!u,R\HRQV5C/hWN
	*81['d?O\@K2f_o0O6a2lBFdaQ^rf%8R-g>_/RjlYail0@j2o_%qPq"addg&MN`!<<05!tbMt!<
	!Xp"aUCc:1'<d!Em`PZ3ZL*`5W^)&\+Jb8SL/A;7Q-g9'%F1@L4t*c>*W!M<'m0dK15p:acCOga
	eho#`m6JJ1):O-KN:E(,Bb[`ME;.%eZPt6u6/:\;Af^]gGJi@C+7S4(pn'*E,pQ+qAW"`GHI`)9
	LOQPJe&,iZ_.dX_[:We;e)3.Ghk#hIJu*d+'MkP1O35e[4#4j*8FX,T^0_Y)(1E)+CmX2;\\pB\
	'q4Bqg[nkb*M2H5,YD]3+'`-O"R\P4391orb*lEk)n.l<CGaZ35H*$35ofDc,e>9nKY%G]qrkVH
	ATHER$`5MPQj,D)e;de3#pL0]dg1B,rLo2(WYoFZIXY3N[=L^&,)j4-+^O;RqF>N/R!m,`<gh2l
	8*=aeK_B*8Hj>/_TKkhRYA6cc^KH>?WRJG'!+T2fiOL%)'>f\0Hr2MR]JKA6nJ&#B*5g0em]&m\
	fZDOl!ZYN_)=#iWbP@ijHIYD0!J!$CIgT.DX9BK4m-D=cAK)jR9pec;sVCI_f2_ME($>.;3W/9h
	71DRrP"5]doZ?FY1_uJSnC:_lZOS/YpMn<k!H@9%>GZ2eGW4lQU[bKSJ2mFH^N'F';\fZ=mi$3U
	',/VD^m!bp&Slh"-PoVSor$@RIA1<Xe1b6M(7cAFM)s\["iH/OJDmr3`n/cSe(+1SZJ*+V1D.@U
	e'AS$lD8D#Cq!6X92ANjq^AmOk8s:@:hC9buG</qCdX0PdC11lRhV`:8`@*:.'2`7)7G>`Ie/!2
	jgWQ/mnSVIn0Y,T\Di/4CgpEX*:`>bl,pf-B"-Ko6Lkp-jrT]SE5[aZkJ0gJOfHhfrelViEl@+.
	6^!]BJXnS%I2I/.+O5ag>RBRc1B._p\=WYP5fImA5H==5ef0^GB2GfsAZ+!N3K>nEa34HJ<`6Y!
	<ZF4X99`a8<BkF"GoOqu+arq_&MPbO6N#m.')6@u<f&d;IZD`\`HMMfaMi\:E=TN/u1]rmJ]nX)
	$d"bH%a]T?P6cpfZV2"S66phOs@U/*C,'B8hpk5^<#P_;h_&g,Q`-oShDYALoEXHr,<4GJekESk
	7R1Ci.CGIQ<LH59nU\X&X7c3[iF)<K<g:_s(s6(ne<=1'>(SF'OTHQ.nB*/K5sV^)QR!4lKV$cR
	_?kgfDrTBq^5A9)>*On?/#WgDig&SDq'WUn6aYV\QJ6hAUu-IF&.!4U+"!IaPjR3>Y%]_j9mu8u
	D#a2XhD%[>dg:Tr^B%rlXIC!6oMjF=(\?Y`:H,K$c=bMi'kK!&E&Sd\2)gLfI]?#(DfP8S1L;Gp
	Hs],Z;qUG,g,CP'@'LkmYP>nUH>_oQbS+D0&C]dj'!lY+WFf6k7+TWS1,nEX/L!7Ir]Fl8^4,H"
	^F124Zg7PXVKW>MdLlI(3\jZ1R?VV]F-J:L`CYA!*O,X!5'4X#f?H"h("I3!A9g'2s&/G(#Ad:Q
	+';1#,;^;5>a>>oOT(]L<ld`_^4Da-"gqhQ8E+f]``5EPWJUS]+Uq.ggC>_W3,i*5Td=HKKqToe
	GhOqH$'4b$d8:6EQl8>1fjTi!o_hN.!1H97hkXL<!"Jg>`0ZGH;dD;DeZKW0m^n\TUIriiCP+5Y
	B)-^6R/A?'n@=nD>8NmB>D8T4_aFLYf)dd_2Xnp1icU?67MHoBW"Pl8)c%a);SNM_&@-3E>E+Y<
	c3H8[HX,*c8:thhAGiY9lUlYF>XQU1$Jn33>6%N"hi?6`CiFf:%duE`I2!I4L3>/WTMJjgj\`&4
	n_.N\Xb5!,aApARBd_d\ihEh(GQ+Y]I[=iT3+bM(SBcnN.t55tT*n\J$ira)`_r5,,(E'%/q+AL
	b7U[HAd5Cg(YA6U,ZhjH(Y>gPl8G;GjoccsiHBK]()?Mb.bV=]9#t.aq1&>-V@f.``fSEBk8kOS
	o^K<$P;hkXM?Y^PqbdZtc";Xu@LTEDp>LAmT3n8`5a;lWP^lL?qc3FVXV58ZLi!R+nm2A6nO]XI
	b0GM_:lb+@*i5>d&+Va,2C.R&E4@?(kH`9<5#Ye0m;V9&dOCfsP3C2hh+YW064Q?LPFYUmQmrGo
	3ZYUTu\"B01AW$b5A\-j\Nu4FM"=?IglYgpLiYp=#ashFB5K9$O0Z8\:NE<j9`"[aUjDCBiKNZ'
	DJ:@c(%jFCbVHl&+%,**peO"P&PSnRmC^NU*rjT./CR.FD>4C/s]04N`n)mZ0F`:9QG5R(i(YO'
	;0nNXITa[I*9UP[)5sL#@^NjlMk=2-rGj@9'\9NN"3OF435fVcki4OMlTXb7Vk"1:3XsoVk9$3_
	aNc(Joh@'-.@]GY63:;7XL.P(."4jmHgeH@_OPLV.Y%nsM;AV>N[_CS+O_fj65Og.*0^8G76:O-
	N.W6$"92;WVC2eb<].\sn4"KNaD/Z9WU+`=\-(.GZ!!f=B2llVTXsMJ[OKZ^TPl(FtZNnqGC)/M
	X5,X`LHNq$*:=&u^\NC+A8-Rb*_B?I:N]P4*:RU+gFBBPCfsb8rm[=jP1GP:s&fEQPV>c!b4+Eu
	#DPD[[-\V8T2S*D.@9=\l_14NX&'0tc(2N7RhF[podYBn:HWLDVn<2NFT=_glK>>?V=9>?DLo9s
	PD:Ym>B&YkP4:d]P-o7\Jq:C.!:Y4@sWbYJ!s&6V9`,J4+p)c@'CSEgj4(.m[n?OpUcS/$WHH)<
	Xk)1<`1$aCiiSNGa^N_8,]C[>@ekTf6I<^fNdSEVWMf1e1d.mtI>Vn^K.3VcdibUH"H7\isE*J&
	'Ce5O><rg:8_CWDM#]?JSAf=DF,/K%%J%fDIT)2<bl7@ddTnY%'Fg4k'@mhf0cdX.A_2\blVUeT
	4<kBPI7JeYSSKf:Ka/3.4uViDogPXlbnCGd;5tBi4\%XBJ(FmB.a9@4Zut%Q:9e7mZC._E!o2DU
	H)>E::@sr"\/E\9*-d=OTGS>$>(HB[^21i[NJU^:H9L(nq1C)&mO6#L1cXZDil&<VWD/9g@R);o
	)o,m2Nf'9Mt;+`qlR#@:cY;916%VBO:7*'J%+Z&\_h9UJ(fSOJ-j,V^A,tr'`i)Ct;]>4\aps5k
	mR?fk;:/f5Tt8p7E\qm]EXTfdn%e5ml35`;]hOF:PsM,:_l,0jKuZ<j(mh=#t%mV+"RXCi9/geb
	+D-Hp<$(;j1.d^=QO-=S1o]hK=h"/AsN`QQZhT49ipJ'pN0kf[Bb3S,=u8-#G!"X1+)d,o+srP*
	,#fTeuSPl^=o!0p&XM1;O#3j5o,OI;UVs>3*r8Y&Tf"%e41g]M3GXK+hA6oNPP<F)I,a;UR6>cS
	E%6eX-sVYU#;;JQp8Z\f&M3=!+)_&,;/9r'@8s;ehYFIEeQHp9r-gR5.m,$unc[!aKAY(#,:s3P
	dGI`SC.245k>6L??uR3a,d')NEj?QIf9h^NjAl%?`Ki)P,;3!8BO`_W6EqCC/99nTl'J0U&h4Q0
	3mDm5r6E=ub)u0.t@K+h<;er!#B27QCb1I50tjrF<Dop-"<pT>S4HkfiS:g4Y7V/<k/BGEr+_:[
	8fCdBQt@*,>3`Okq$7J?[g=Q9ZI=Lua"ST@P6k]p%6tIgKl`oCH`[S%:.C>PV<kdLW<>OsoTRQe
	DT2-D>?@YEuVPSgS4kEPTGi,kFUWK3Nq\ms?'PZIS>Oba,@</7N4'+CRE/4B;qgI8*V+@TiUt%Z
	m#(mR%l![ejUXWm4Wen)6RRj0i_Mj4r$2FtoZbd@nge-Co&jTlW:OTQ=u2a12`+Tqs4F(aS.N9[
	m?2%67t,B"aPL3H]1ZlVGt]XI_R91G5XQc2&sE0&=^8:"^nSUidA8=RO!S5)5a-?h#eh%3k3rUY
	G$Z<Lq@rh?:<Cm?=Kh%jT4/!uua*dlgn?&^;,sI&EK@?hj*.o>.-qX2am;(Pkf0G8;C[bXg=;-u
	!4X4%7lH[#pb%!&7<_k+T4s\PBKMZ-2-$+$nA_I94@Z&Uqp&\<g""Zk6Kem=\>V.rLTiV3h_1E^
	(Jfn#ImAFH1el#PcW_?5T9fnT;GcdToo991rP+33FI4OF35)fjXcuB%XU&Plh,+EF"r[DUsRpGA
	D=]T+0QQ>>*GBc)KSl("10a2MSZk2X5u81/E)n!&QC&b7XhoPT4d&<E,.2QqB#@cbpYXO4g/B&>
	b_M[/U+<lC+(nCNC2.4OHqQ*dts>563YC(ig!E,lG'kT/40@S(Up>cf.>J8$'+gp<i-lD&c/bN/
	Z*F82n9`&\B<+*+4jY83=iXM5rcMZ%$9`!#`t`HoJfEX\sN>Z.0`uhYLO+Ltrf28LH`I8,tk?d]
	#.Z5qS9aK_o6SH-JDggjCfWphWm]2_E'ZK<V>b=IF$X4Y]Rh*9s2+JXBWdRhb"#XJ"^`MeIqtSA
	4tFnZ7;n$<1DZ&R@TNR!UZ%l@'>R[W]2Pf?N'l$eD\EB(Rm$dW[g'`0tPVYDBpCCBT65*2GrV5,
	Q#.FW@*tcShUZ`dGk"8_H;'Z*7p1(gp`^"5"MidPpALr)W*)el$8VHHJZ/oo4I_W,.&Kl]te92b
	-PHP`E4Ff;"N&BMmJm3%A^0E3`1%N72r2HNZm'A*&*R:>\\,HCHJl-&WBI)+aLp9_o[`&nD"=f9
	4sMe7ck%#1X_E,=09-JIl'j`H&^SL;c"''1qV5)P*&G:P@$Bf_2JH];#Z_'H0.bmQf9SGT_,c2@
	+p/r=2"O,k\%B#GG<a9KJFd#MuGu3K.6F:j@1lp$#Z"2`$XX=ETH>;)2s3a/;4/%LU3<g7<qiLd
	]W[']:pPE]SAV8ssAJV8Ilp(j2gcLO5A_e3()F%7`"mjt_)&U15aM07;?46qNdYh'L91Z.saX7[
	bOq/%h$?,`4K.hqb;(/Oc^#gYH1_'D?3p+u@&Fc38*\c)NO>[Z$50?9kb'3Eej'[.@;@r5A2M3a
	FOB2M"\fmbN,jGt-r]<]))Or7,cRL'+-Nq(,T%_0F..0X6\_#cF2aEF%(&I83tPZ,'"MD/XDOj2
	eNOMmNX.CUl@OM8mt<aQ@BI3H[>&m@e!aW<7]W8npCCQ.'d+Z/J>kM`jQC`o.Wl"B8BaP]SO:>*
	c(pGZrbS8!X-mk.F<hm.MR'ChcWP8(Ou&Um]9YG]n!:c=4,gRd,@L5_Y9[/$:`D($*YS6^qRu9D
	t6j9B&OFk1"9XnGTBcjaZ.28$XSZr(Tkk)H?.!\X4o_8s[)ol+0s_l/;RA$sGg4f'TR(+u1C8<?
	^?7A*#mN!HFWP#/'24($^.NI&kHgcIh(=_cEr<c]ET"p`if.(;4^+WS%0)c?GE\Ubm*=HD:rUr`
	iOT@;A@F9fTbm\au2g:5)2\UY+R=]YY3hG,X\G3Tt+sb5(_4'![_iB?JF/4BAE"]+DX9%^f=\aK
	G*"lW0.+A:(jEFsCBI5bc)8=Do*&etpCHN9j+nl&b'jeFFNhQPA]qYR3Amg+u(I;@]E[4CYU\/Z
	L^g9Ba=)[mE"sU+a&TML)"d@9e=4b[0D3:cAl"3?(DU,t!R5@r9C)nLiT/psc`U7B"M_!$3XKBX
	B<Z!-@`4btE43+g5Pl:!+k^\=?)kFi9b?^`Kmf+uO1@X&\'kRNj.XMDD>N&W$UdD]'PCMBNbl>E
	!s&n-?'qaL.'un5$jW(AQ8iinmKLI[YOCNi(]HJ.CXXjhK^rf:Q7d7ZNJap0+$ZE-5r2Q'ZZ@c\
	&q7r&X>)7rbV'-]>B;DeS3jV7_'@,6s@d(FLFI$Lk*+nMPED]"]?%r/YTY#),3Qmm"VT00E#6rU
	^P;VkVmK-qd3Y!:loZ&Zup7TWSG'D-jDe[C(Dua$&E$lQ%R\Hr[B+?f/;[Blu0%Xp[T2D7$lE*s
	b'qWooMj4_WnRpd`QbkDK%%p4H-T:ATC2KIoEmXVJ!fa/<(0Y::]].bg1UKWa[N$^NqhDaLO>C#
	9]?/:9h6@ZSDJ(!uU=4-;@VIlk\.V7j1C^a>.,aScinT9JfHY@C=3T$=.hGU($g*OW?,4@c($C/
	_q_pT8@STrqoNR1T`O=!<qEbAqjH966Db)Gs\.<U[us"[OHCTU3A9nNNUnbfceCgpNk8!Y("e?.
	iSLp/&\Z"YNmM7s3=B;#R78[?>n&XX<@/8G)OfHol=[n6VO=n;PeZYT[7j#8uU^W?t9iA*/ghIa
	^LqD"Ptm$U%[!.`1KGK5kefUn0of^,_C+,2dFT-mSi/`Esg+0lo14Fne>o)I6Rag/[4<94qrq)t
	0A@;(")`N>DhcB4,a7^t_I$H>6_2qjc$>D&q3(nK,kDnG^#(c7\!F).eg7,`=Vc&K,ZPP9Isa*K
	LFQ#s7EiQ&c[T=8P\JpohY<1&1>=d`YM;,R2V@&jk?2[Nd)_.0()_3UMi$35/D8.4`$&9PN4D5r
	aRhP"+N-S2&>sTGSc-WbJaGhBVg-i1C?J-(^mk>8qqNPX$Ib:kO3P7Xl#%E"?Dn)saK"SVLpo&-
	_,fF(K+r`%'!Za!`N$-j0O&+9T4Xk5Ka/P,?V]P%U.gIb3:)>0lmgoGXT^WQ#sV3fTcbTo9DA\]
	H+g!'.kBP[^h.;n]>p61F&of>NXfXn+Y,TADBk%FbqFoKMqCb@24CkG$UCf!\,N,#p"\PKER#*1
	JcV"BoZ%]KT&t[!&_;E*IS;3R1DdN_Y'b79l[iphN[Tm7\=^ES[St[pCJm@,)d<a:C92oYs/URa
	=b(Mo8p.nP6:I%=c8s>#"aJ]I@nXCNA4qC1:%ZY#5X@K,%E]U.8c#!u;jfTGk,L`h%rEA`?@tKP
	u4:9qhReB3sD4MUci0JXf<nAPlBEbI%U,bV4Uf8L"pkYsi"'pqHXEZGWDb]3#kNasNQO5/oL3Xc
	Ymn8!T:ZJ?kRQ>9L5(dhN=O*>c`QN?0,81#Zmi$$]3.03!E5C%B.o[g]Gl`L^>0cH_%P_Gc_!!0
	8c\S78HfmE_[sC.eKl:QRaXq"j=8VPeYYh!9,bCUQl)S^S&T+iZee\,bs_pfCEAipL;)>l"P!pt
	_nD;!IhjQ)$%CiQI]>-8uKj1IT#eP!f>VUbE%)[g,'sU0dCE=u4KP=+B/A;b]"1\fL\CK2J8`\%
	QM;e1Lh)9>psq(*lB']8A[($q#>\[I7kUUt)h3SR919UA/o[k2FS9Yqs&@l-gaHY9<o%.l\hIN"
	Q-d\s(Tn7U-up4qlK=q=Kd;ASlW#o@gR*A%6bg3b3R8i!CB@U+4b6Q*"Qg(ImqJhCnA`VPg.>%+
	ik-f$[lZ<D^T/MOa4l%Vo'WWJm$E*DWNl.==.N_f.3HcJ/`1_uP/Op<QF\;<E1WQS,)_r'o*+r=
	/EmkEa]T!cA&TOhP_#$4_JJ]QL/lGHkmSl>tOkZlam<]MCG>(96Nb2d!`M+cK+VF0mXH#jKD44A
	t9PFLg(1CGtZ)Bd\oe-tLP^'BL6=S8^W*UaqZK</0th/$!BZ\@.Y)a"0t'*D]!-i/_kWOY*!LlK
	]>R_6$[S6]k\ZaKCkDDSELR=sitmNt,@7)8*@']%3J#TlMA=0*p:d>ktYYTp:]8_EMC3HY1g2Au
	VTp@D4#6Uc-&_;R9jP]d_F0Y+hFJ*:JV57ZDl]FKWA:rSsFH9lsB_n^,FIja*MRB;d)D!/=K[4[
	j<LZuoW.@2+k<[/L8u#@ltr?tfr$TH@$;2>`rq0?"fb%IQ%:;"`JSKpC8-6-mnSOI6-Z5^V$`=!
	5,aNq#/X_mpK1EFNW<''E%FT9[oeF,JdEaeLcVm4=)&^p"gqRWl7ea4a_9XK87p0gpm9b0.e#nG
	PdO5;($)Qee0#`h:`9:ES8d;3U&P8+/sG39T#,'i*md*JtbgZHWJ5,K(9#@-`D-IkLDqB+m9l7\
	kJT[u3ZOI#\>"+1uFJkD]@&l<S7C;Pg)59;]C]MjIij*0%_n>H'%r/lmlgRcJJ2`5nj:0QU.M`h
	n_0emk$M>:o):aO+87PKP'&j2!qP2mHSPU=0`,J1o_CNBV-8`TX\mIaTRhbQghkF$!L)/^.Q5k]
	,K7-#uPs'so>u3QC5FDkt+<42Yrd*+pXqDp5#[b^!H!OYUZl>;jZUoCc`4UsaT(S[UW(B>oVW:_
	=N>*92JX"a!(rj)YOWjctj-`Ytj__TK3N3:&X_f1$3*QF,+A\]cA<iF5AM&a,<QC?`%[*6GfqSr
	9INJ&J;aSg6$5l8lDVH*[4Q4Xe'h6#;smE3NN%fUc3JBh@'&&\H^:eqp;09.UWB%+btUUheK3']
	cB?Z.0Q^7s(1/L5(UM[;.+d\P_Ekb.is+5p.7qiH8]`+edJdW9Z$1XtLi#BQe@2BAqFL19jr`Q<
	<)u#Ou3^Mun$GJXY\Bgn!OWS#Ig:,\Gs3AVT);P3K&BcI)b]@5j\<P()VD'V:frHhnYW7pB4nVM
	8EFnP<?>0@8SN=QqklE3]AEqEHjX(s8Ed-PuiHE[om)`G!BUD<uP_`kU4`^flJW^)bdHA#sF3G8
	!KEC&Vp[Qm(1$<`kd&[*E[4/-.!s>N(i>;s'u.(tVT`%U#j)/bleFQc"-,6RE4^`[-VV@.de!+R
	rfWKrV3&k3@>3.\!23Q`!1p)_8P8SdT=jLTGI$&'PCFEf/8OF!WcF9[U<<5D_7+]$J:*[Eopf(,
	E*9Lg%pPUCW5tmm`ngXSs&$\XG5M&FnT#MP'BrhqPJZ(I90.PHZnt*JRp<IXdIYVhfh2RR?d^na
	Y;pBss+@jE[2I5L>kFqbIUJ:&LC8>D[bEhM3cNfAd^F8FA^JX^/\nI6]7]!74LuIqiEZFapo.fs
	UNsqo]NI2L(N<JIK$a'P+.]aa`I6&Wuf%rj9GIkZ[4DmOS/m]68'VGrpK!RbC56orU.rG@DttF.
	PAgUQ_5EE,-hie*.\D)D%nb[@7"]MtUu;ML>9^KOg$qGU<Rm(odMaK)74j.:mWdSUMo5IfT.GL4
	?PpqH_+[B-8(Vm0=O/!*AL*C&Ol$Wb_&&!&?dF.eJo%J&kUfSpY#tZeJ[:gaX:"IBasuO'+BkIq
	dlQ^VF40\:pqUmi-K?6cXLYZHG.Vm2PPs("<j#cV/2;k)Z]SAFuMWr^6OJ.P"VM7j4sY?WkalI7
	HlBYs@&;QPSqeT2!tXIi@X,>'2ZTP;t!_V*/H,N7apSCKDIC``=b/FpZ2m`M9+t^C9GJ3NUpmM^
	M*5\+QihC!C,*=+NoYk*(WoAA\1%I>+oU*4@Ac2e'jb,8gVs)>u?fhf@*LL@4\p(#<-2#.^X$n=
	bu0UhM)!+FK<E/DQB7A)=b/Ml0?`Im^(M8sM>9?>$M;+5gafW'\pWJ[OfZW*^0@]r8>s)*K6^`N
	l-q!+7Jc#E%T.@l\6u.=19$/A;_IEkeK,=5gh^a2&E72LZ"]ZoRQOQ5^W2UqaVi1.+UO=:CpjiI
	DdRf"Ch(X^,\d[Jb81TaFd!!/D7g:ESh.&?kb^][i+;W)hfFOKh8E#uk$Jq1A^"E_5N2,f5L@OY
	h*BeXI.Tkh7:L8fEcDkI>\4*1)X1o!fbq;Tr7*NcEO>RAYB=f/cVV8<OYK@E?REV#CMq.U,S^6]
	UrDVJH/e]X71BO/;)Q_DGKoNE9([RP!IV<FQq%+#a_\L2h_QB<BE8[\lPHS,WHqcbU7M`FCg0.!
	.C&>""L\b`#&Zqand/Jp&b;!!"Ko\co6aoC7m^4t?(tRh(/bjg7ellM"Uog0;N!.ikj1`2nK-gr
	!p"1MH*n:""5B;0s@Jn;"f.(E+r^r%Y&CHWJZ?e'dOWr'bQL>C1/+,Q[&+"nR;Q#$:];o20pAb3
	3m?+1&\^j%g9PNt(fD%J>[[l!p^6Xa=aJ%Lp9ZOpQWN)4PRsT5(F0JU;9MkeFEhZ[HJd%hrAQkl
	Q'1[TsDkY*3KF7sR\]V+/mgY&\JO-A$*#XZp?'$sh[?g=E='G_Sc\#FBVlJq\p]a9&V_+1_[,ir
	^9$XU&h-U%k,9LPB_`&LHr!(=j$=ZU5@6,$Z14B+2QcX;S`g%LsrF]-c?r@6>:&C0hZ:D5;5e\p
	D=4Nndk7*`SVJ)dri=!&/X7lp7>Pf[\BopeThWL3s@\Xko>>Uq5%e'cMe]O"2qE)/[?I1QE7SE^
	hM2$LI+i[PD\T`/`L2Yg4S9rG&NFG<$0Pr$h-E`$CI&N@*LtM%uf_>XQ]*:p(9JI5!IIG,FX#&o
	DH*qX;:\?J+KkiL^n@Bh<.kUUASZE@O:o*$gO8'=E#B]'a$3V%$[E<o!=!<oWO_HT$p[K2G++KT
	Y*%X!Dp41jK3;],VG;$1Ght5qb$$9nk>RfBh`6M"un:%+.[:!tG\!!lI5"<(UG;e$1O+j"mE$jP
	F#(f.Z;QD&q+A#"Y0DI>UeKr$Rdm!'.-PKrn+-CZX$::GLW[0lDO1!8qlR_;gOb/]2%_a,6tdU_
	-d:_fKkG$!nIF&*5HR7r813dKWh%+VO%e7'\h52"JRY"Jj5(G@e'Oi:5SEC/S5eB:XE9do'4`1<
	S$`&F4XJ]2!:I/7ZH)H)/Lg]2Ret]Q0bTJ6O12EjZBmPaZWt^S?04dC^@U.m#iFP?>PUXmU=;92
	_#0/7hf=K%O'k%)d)i;KLE`%dg](hT6k159B`@V>-hF%^C5)X$q@=[,+6GBK!^e/a^"e.*,YYcT
	=WBk<3UT4cJ9>c1O*!YB?>8\-L]h-$Et^o02/q1"WTY&)q?+?op#mIO`etYOrtECGK-f*W=<PCF
	inZ6S]+n?$T?#j4'#/[F%To^?L>Bhc#H_1i7a$rr@l:e1IE/[t8aeg1iQ)dRNU;Q<"I)@9dBL&$
	AD*)CHIeZkOU*8"f/\4d9_7U00%VaUAXfZ%aA62Nr_3+&3&\=?Xop_V84"C[l[n\kU\\9,WC>0K
	E/bEd(o!B8UFV>m8H7oUkLIX6ZAcZrYU4>=Q'1H\\/"7p2Pn<"]q1SZhUJKD2pqD[LD_,\K->/C
	1"3`g/[RMfp82&;dteEO;ouI0[GC#8a?Kh&Lm7nJ>,.WV"@C$9<4fW[GGpV-md\G3"WK/]J;A#@
	)Ii4,mF]oY2'npij`['r'C9:9m?UBr=IU0bO]bfXV6j-]TrV-Y:X>c=b*\ffp,BC]=ALC>+[I!;
	6nn0A'XS@2]u'(oiZ;c.LtGmEJ8:XGaW=i;Weq3T!;Y5gdT<AYd8jD.(gr3ntM+=CiM)Yrq4;i9
	)3o7893iBq=[SiI-2O\!p1D[?'](el#E)XhliFIc2E?^`J963p3V^)'u8G:0JGcFPFu@:u&(j^m
	qRsa0/f/pSr:n[O7?8C->JO_#_&e'&t9q0a$]+_#.su>gXAKeZ>m[M03HmIqHTXpF<#$A:OkLjI
	D/0afO@m1eGE9DP?(G&fZ%\lKI!CZl$HsQo*me$Q>Y)rGdjDdnQs%p2,ufP/C&Amd)NCYO0<Zlp
	>6?20SQBO7e/Y'9eA5.cFG&d"aoW2hq5r(87a8L`*Z3Z+B<IYcc)?%P(HgAN7</G?,b']"YUUUm
	oJ<rX<g2[EU2+:<:g\D-`b2P<;Y&-QLa!C[-&?@bGckf',fE\=R+VC7^Yl!MBjspG?,,e7;FhB*
	@W:0JiBYUOb[KonS&\CIm:J6dXrXZ]\H!3g$r5P!>dFMRQGf>/:,-QnSm1Vq7aq'm%ZC4+!4+o5
	9^_co2EHY0MA9b-X_Of][^&/t7#X67]nZ"ri6k\]3&7E)5&S<s3WKik+S^8b1sKYta#kJDbbr_t
	'nr@eV@KbS%^`Ctt?`T:H!iaH"<hWE`.;Q\`$d@F[Qd,)"eT,h"@\`X*bA_$"8_lWm>cf2J,[n'
	K;JQ\rF/YMW&kBrt"R)QU62lfU[/k8EJR:O:pP8b=auMX#MrQ)?FT,_GG'f^ZkQa6?j7P3T,dUZ
	ZY:oX]ZrZqfre!)1E!IT5?>-ZjA`la+j84Ai^@0.a1Z?!bc(h43bJp-m'8AJ)QjZ2e()d<<'LeR
	$52G6#0"h+$A=W3`a1="%i_gRE@:(j8(@.\N?O.i]@^4KFrpKg8"aL0gP)FZZLBNi&hsS_Vq([,
	+K8ER@QsoM\f$k;]p:G+&Ykie'dmY!Pc)4;6!DER^rBQ&aR;8iiMULU<7f@[L.'SqE!R*D+qT:l
	WlP6`*:cK4mY:]E.i[/!FT12A#Z090+]'*O%4lAF>G$(%&?0iD:Cc@((6g$jPhOUNOOr[4+aIWH
	+s$H,P1Dp&>")BfFUd\p`A#(3$D2'5C@FG%upZq-`S7GQScbW(suFlg3&HR<,gF.I/$%n^aVsR:
	_(Oe%@n]p81DYiprRgS:Q>t5[pk*WR#c0p`(KKX`8F(X5:j5mXaAg@n<kZI9P@Ej%*SnZX)JaAB
	ErS?fi6i\L0?=Ol!:t:?c*Gqp.b*3IN[':Rf@`WCSDMGg"69i`DWV50Qj/Qf)D;7Qktu[_/Z,`_
	LH@k(]q4l&b+TIB7CT@5dQV4:G^L#V$AtciA':a%o=*e<J-@$86NTL=Z2bOf7'9C-$`+9[>h0rn
	@gE[?9*L8d7%7n6s=<RZ5jUIEuQ9e`##O>DOZ:R$$N!nm.W=4[@*64-#PgCS;8:]Xn((Sg>0kZ<
	CC'U-Ph2AH$*@E!Acme$@iaMd<N[JL?GaCWhAHRa@L3P9q#83:2om:K,8Z)L$TraAh\aSUDrHFd
	U_<3+N.J#5f9p<db3ae@?*Ij0OVS9BV[&;I$K_Q-TI05K]7p\Q6/X45U]c:V!<A.n"nEA?">)`X
	Y;mFqmT^LiH^T%uC3,8EFW6L6q",lu=DU"opfmf:!MC>I#W;a*L(I)0K'KVdG^D^eB"kq1'H)lg
	%-F_d6jepr?)F"Mq7p&F6m\CO@f\VqkqEY>Ip<WZKn4\"5Oc<KDU<U+']lrLabCI"(SVO0)8;AM
	`=q&*a8`Z<lei?;kDJhW^5CccX&nOm4[;oq_&eCJE%aZ"Q%>0\C-%8sYpA%##+l1,a3_,`e.CAd
	>J.4Yid1E0?GlW,dQ((E"eBi]du:#BSh*5sKV'3d&V1fkqAo!<(O0L&d:<>5J.T-9-hTCNJRA(h
	mF?Y,Uc/G3<Z%f0`">G%QtVTm$T@[F"0eE=C&]2!dSlcZkerOSEqnC]9H9jd5PUJ-S%6pW4\#MY
	")T\57R]]0!7,8`CODm#'[2r-SC=i[$Y^)'Y)-+jt23$XOH"!K`%D!@'[FEF)&<oqf'Ylph(K45
	HMsps[.4c1(I(dC_8N'nuX[a6bf05dDqXJms;S.te#d48P&l"\>e!:3D"Dg!pp+Qbnn?IN)YhkM
	_GXGAX)L-Hod6(+?#;;iW^*'^)%5S=Y%i6#?(OF6.St^1d7(T$PHK31EOgk.CD64l!Lo2eL*0[Z
	g'_%]#D0#q(f8`XaH!AD0JKF/6S@Q&JaUl4qdF]J,Re2Wn"0f4j/ugQ6^_EKWU1:t3''1umB_h%
	Sd;];=iEg+59CJYD;9OSuKHXmT+"UH.99.S^9pYWR!m;H9lGY+=MJUTI+glIY?G,*KC#n_<k:=s
	;gTS?ohIQ>]"g'^eUIGcD->[>)VEP1Mt/B`td1R:DYX6+Na[DAON:L]t5M=.Vm!DW[(<j*h@*XA
	@ho&BUr"7um*b^&'.IBrB]jh*R/YKoT'V!jW5g>RcGkjS(['+"Cp-CAKiVUhUZ#?hfCXe)qcUgs
	4Jk1qJG!Q"*i_rQrV3]W<grGl[!3Ec4?L9;pZ6iLbig-GhDn^CAqu8Rd9eQ*Ze1nl\9DX@RJ1X,
	Jr@%E\9HTq+,m^)?]iiU2GhDM+c<T5<]X1G"PiBcA!Y8ApZd"p[*f;9[CU^?47RS8f3],?9#Yc!
	hIlS7-Gbi.!e)M'/B*QQ_F4c+&>SiH%^T#fr,p:1Ztf@#MY?"EBH@UQ/+PY>\IncZkeq3duWl0=
	@:Am)rPc3#'M)'qC3e,GtP&NWqPp-A?&L-)+^[m5,371h1;^'dR^-Oq%c`9)=ReB=<[lW_a7o+>
	D,)O6@$Q`6e_]!RtY&kOAbFA@,uSg%d_<rr<h`T:dI[VfHT`ganPt`nW11pXfEFY?/5kB'#=4*:
	g1PK@:$lNB7S7E)&)@H1e.MB)G`tN.\@CGHa<.B4?a:-2b?D6R6j4fe!5J\Trsu^E@f2/92"V/Y
	5"ESeEO8/:91HHoPt1;p[?/)c*rV]%rhY&]lEh!eIiKKH%C?\#2Pe(/Jr+gI$tqdAZj4h-7kW%h
	%S^W`r^IM"McTETYsjN5m9tS:rt%pUT<H!bjXO;5kdme,3]qn6X_^RUu?)L0INg.BD@j;U7M6Xh
	9V[*,*cZ`m=C2%"PD!$u&;B)\j'jF3f:urmD^O`/bJdG]uL*KO,OV<J'O8I6?[h`+*h)ccZp?8A
	actm`kee(Ykn"+$5s6]Xk_bPZZ]ue1@GucH%+;OhKM?TR<[/oYkOB6@DBV^)ZH[gUm8^f/?JKBe
	No,NNJG*!A];b#EH@^>,*V#lT>FA_YW]t9\4A<G>3q]Xu9PO<ga;q?nsFO@R2J6(a/LSQpUfC0q
	>A@4nAUQ;:Msb[<nd?;2T^OD"d(g+sT#LTN9/O`_JSc7;geA0JuR'_>!2BHOc$K2*2Ri/G9ERML
	``_._*ba!-3'^\LWo=c!>[#L,OW#/mdQ!lim0iQ8XSk%#rOk!J6tr^l7:nH=&d@_W?2@CZ;gWYB
	?HG7<PCsD07uoEIA83NX!jS!h^RPY&HOPZUE9NRtP(>Oca)4amK!T@H*a_V/8aNO`M8I<fAf(0H
	lo8VfK!A)G49"lu"qga/aH3iY@f9[#8/<(=nr(7S#,6]Ud.IWl7N`PI0A?F2?0pSm1J<m@ia8(Y
	?$B"&HOG@p+RG3LX*RMIG*Z2ZSk'3!6VmeoL,8>+@g3^+O,@/=mg2mOp1GFXu'<2/KZ"!$ZB=N#
	<@j%QGbhEho:k?Hk;B9j#p7hhiT.mj;m0em1al%#`3#JGG<eDFr+Sj.(8Xk\Ea]FX9P_;D3u8&b
	pk6D\:ml^+GPeHMu[<QWC.4XX4kbU(ehc.PNVXG)Z)@\_Y``@so9FoH/dZ'YHBp)bIHP[_@XUem
	Ld&lm$c-F]Rh#@QMr'f0lEY3gYd&0B&BKVe`)jg1<S2I*Bdi[Z5OhorRO-BThRcec$tAC=5b%8T
	^mn:-?bT\!nA"`&;Mi=)mJjl2gPMXSF49]oD&_O"J&oo`"n09/kPr30'i6>R;<O/dMJ<q*n*nA-
	:.#!!RIM_fqh)`>pJflIbB!_RD^Gb[`tD`TKb$n['C)EQRCH1Y8I%RKM+>*rI?l%U>DSD'E-&n"
	5T[5/#"b\Z/WC^s>W6_pI`hO;%8hB-L*.HN:3N%SrofO>rNpbI):\*DKB5A\q$(i0n=JW,j7Xd'
	QI,o=/j?ES/ONZ&_btHu=qL5..D612>nmm,>I&nc?eR3`U5-,;W?+R2(u%TA<!]WEG(JbaM13H&
	3iRm+[*ulhmeM9H2:[,$Z!qL"4;d/98;I;oMS:@ol:Ok.7sIHdiZR-Yg@MO@QeOWI@8`gi:dH\C
	f2c+p/e>A:694C2?nqJ&Ruk[FZr4;M?&RB\Nc4SG"2:euh%HfuCktq)gO2>f3<>[ZHi#RH#4hLS
	'u(1X?9:'@>oX;pDs8UO5JWln7_'OoGEh*_B=,F*>X0jSYhd#:$b)Y<6f*XN8obNsBp==->3];b
	6#]L]V*V+>DuD4o"^=;(/0uflmAqiWZO>-]_(1B,!HbqLS_h#R?,0jrBGUUn_LC_j^EW$V`FoIN
	c:(Mo]&Dq1;=)jCEj])fG!SOEqCP796KiYG[dPcCCKF%i"e.lHXXPLJ`%)'!X5^)$q<Q5m/9=.r
	'4eZ\b4:96AB.D*LsR=5SFA4E&M=N0lh!!k*5#26i<u7F]YqnE-P;H-nsAjRe=?D#PBS=Oj=Wba
	gc_@YOg^L:)k13p@G6[un'SPP?'I26!]<OdrE#HLcm'I^s0/MfGWN68rF*_VC2g$9>(Wkp-Tn'%
	JeJdkq[&rAQALMH#'<&cF53ETWRBFBt30bVkeKc\6Lg`FZMZ[4,oq6k(q,j="qS_su`sB%1@cc!
	u#GcPk7!-dsqr]3Qm,aBIOjU]+If'UoWglsqAfO:S1$m3Q4>C#%LQeS_bqX2);JR(B@7p96?o=<
	df2NA<Rba+8a@-bX07b1")Do3FL<1]2*-Om*d#f,!a^-^,RHU,Koi6KO^P?r,WB:Jq@1'^k<UV4
	t\Y"eF@SGZk>KpGZqN\Rf/9XFY]VF2:_+T').,I7`60,SO<`gp1)!)3Cq4bRAMN!RREaRM&n.S$
	ta[f('cYTT8-Rf\_/!E27!A$46#cY\IOUZT<cf+h*n+,l(DLYjY$V:/4UAkG:nq8?]$g#*$:L^R
	SfPZ)C\O#l0;[*:4u[]et!-#@l&]mVd3\91o?_enm0VjL7&V:R_r,ArT.;";7@@\Fr&8gJS7NcV
	g(h::^7/Q#gDh)54O)5'\C`#hfS*2Ns?@`WgK^oI4Nsg..*EWGenUVpXY@]Umd"cERU9<OS'8i-
	jH<hN`h<p3n94oV$_MRO_L`WF6kub/Hp+f7Ga+Z)(j=7p4Fr,\Z11BqeWjKTC58"ue$1)'jip3T
	O0cK\J*C?O6RD1"4alSf#2KJpHLhQgHL8@/GL$raMdkD!)mFEEP?0j1L?d3PCR3kWcC4NjTXg9i
	>7Q:+)`uiM:DiEIY*$nMJhNROSttQMa,I3V\M#[^UJN7Z`4'&cVj,1m!=ME2lGh-A^Yi0=&O[8T
	dPL*\ic1=^5/+[^qs_8lWcNL'C>%!+;U`rjHUBpFt6<L<[E[h[d!VnA:eB#q_9jl-p=2T?=%SW6
	V_<eLW:/RqkisB8SK^'QPfMA_b<LN_`>ggQ/He5(TEBWp-/FSp2^o5:L(u>R'dH:GJTr0t.16aT
	i^*cTd1[)RlrMcLj3&1qgRd9ohHNparLM(,iYqGJJAFic!<YqU`+p`gjagdGiJ*W4j%8#*JD=`7
	i50RX@$EcoZ=3>[Bo?,Q7gAl&=09*C;LCDt)8Di2aujV>-X9Ac"MaVJ18+f8Z_RQJs.M>3Z#.[i
	6tQ1-n@#;DP5'=i0RAiJAbkMOD2eV&O]pni^_j:Kk'=P5bM<`#%?UMsW1j8(@MWl<YXEGo"A0N_
	q8n,<.GMM"`O[\PT1I(kQs>$M!4:;GL,:T%%/I`C;@fl5ter"Z.lfe)&dQB&caL?b*U:V#,F=SM
	otH7TE`o1.,Oh+D7>]j(,]t@6$qUQ3RG=j,HM[DW8u>JSf8P;AOLh74n+@$k,Yu2:8kP8RHO^%h
	U?hX!8G954G!b:XeABV7u'FgDE!O!6)&^6]Fj<QW>'%&BAiD]"CL+EK^t[B@PtT)PM%S[IJ?BV6
	er]8Rm*`OM&ld+U(k0pW<ROf:W9<<HO)(@^hCT>oM]mNbrOg;MmW\*h*hs/%Ge=r7M/J%RO[^Vc
	e*oa_PrQp\(<NQEb2of\0R[5f"3N\3Y/lY9OXhrW]_&EErt8Oj&<leU:'_cEUrZ>M_"GbgNkUV#
	0_/HZZ;[Fsc[gfD'F-/YrOrOf:ujjqUhV(r:'ZW$;Xu>k+?E[3l6nd+"l"B60sJGO]O9l!M@=nH
	#9S]3n_1+<6H^U!\MV>,sO1l"ki`X8#4ibo5&09^[0WAhgjo%S,KsAbC0=Ac$,mlh'Z"0>a0BEf
	9(kdH-aLgN+.l;:#cqf!BUHXgK`]MqmW74skME<-=5E?a4W+KkWH;T\YRX:7To!d7u?,DS[E^"H
	M6QLN_br%*d*?SiZSD\Q0l**6??]5j=ee7V])#N`3rH&(<XNV-`DTc*H3jZF[E!q"])sL/L=T%.
	tUkLmC?rqSBg/TuH!Cln<3mFP'4>96D^XP/PX(iRHq[:BYVuRYt=5h9iVfY0q=#O#\J6i!1?!EE
	8PTN-Iht"]LL=a!R@q;S0<YJUfPc3BiGI;IX=^]<ER&Ja]&'a_9l*lrY-M))u"/U$J=GK!e:sU)
	8rT\7">%)>9rCdC-b1;BWd\3<tW:`C!!dCYH`[UMkJ'2kLhs5`=cfJOp!8^:Xr(bpsNKReDZ9pk
	MQZ>*Xm:Q)p,tGaRGg#9f/P1'aJtEd468fU\=$C"\e>3\gG?FT<Na$k*VmS=a/b)@5ii)uLZFIu
	1g,WOln"?.eEU)t<^IUt4,&KMdFtJ\j/pb_F1Z\A_r+^4u0@4R5W70I(hEY3"%fHYB42?71M7=k
	60R0\DK4=be-X!(.ARKupFlFh9KF7!:a4rK)+QF5c^tC3Fp1)WgA8H-tL*R$bgc8d5m,.SgrXM<
	(89XEAiW913rl#OKXm3sunc][@7j;+bHt%[hf'Yt2ZL`CN\5k]e/:k;B_+QA/GP2Iu<`Ho&IEeM
	JidlP`KnDBDBUe"H;;SF%fN-d.*-)g;sJRP-&#"j>Q@ZLJ*Xe[0XgZ"83X`aY#'HEFIY'q"V+!(
	/Yhqo!Ko.n(tOd;)e0m'W<rU9seeQOqtm*QF.\eu*fRWc1]r6/shOUtkO^DRFtGR[gj5++P`hXY
	+Knh^!D1Du33s&'321q2n(ARC37A0dN8s<_a(N9c2^fT2tJnStS=ALMh3)mk3G`Cug,H1,/Ni1a
	"^'gUcQ.2:G:`mU7uQZ0.]4pa`Ik;oVbUCsu/+oti#4jWf$,)l1N?5Z*?b^1`uQgc7AE.W2f(.a
	OG[T$Se54rX3u4?p#;f=GPKLJXIA\WO<I`5:n)(P!(XS_m2OZUp>Q=$9STr&:\@rrCbSm1$-GFW
	BC1\9J5KGUVn0G<uPki#M8j5$l/XS]0&l'AHc,[T[(*>e#WbMc\?b?aWA$4.*AQd?8rT:3[aZDC
	]bW\f>q3cP$"Jlt\Po-.;7r_Me+:F_sb;_Ch_,goC`m7+qi9;35d]PKn2eTqm(^4k0,)h]6s54U
	8kC4h$0Qqg5$J6Z;+o\S]>X,]_60gaGBnR&OuBUtPAML%+&C)`pbP>H^3jfUcbb7,5`Y`rLG8o3
	#a?P!(GP^lVjV3JpI3:k1[;QZ4-i^tZnEaih5h7>jrso4cfQ8YeWB18`/s+h)YUlo5m\9cWHPP`
	EK89o?tb5AS\+ag^E!blUsVr$UUCN_XOLe!eUP>o@81Q\K=ZD.#9q+qq=AG@aX4-YUO?rr=3=k5
	'o$[#HWQ#S'M4jKfhi=@tho$ZH;)=kp%o6ADHKb4AiGEgRS5P0m1j:No,kq5Vr$E=rOfN;t1;2M
	@8HU1Hf/$QtX.%jpheX\t96-((gO01qPQ9#A!3D@TKam7#Z1)4,Y#:>;%!C=,`"`H3jf1jh"\AS
	Yj%-PE?N8k+M3E'5Z*Rha[P1(7Y4@+ALP2<#&hBJ"1]SFM7+:U.#HAgZ4]G^I?;6$?PTB-hN5PR
	j85A(TS,Q%YFI$%+H1UWS`."@"OR\a?>9gue9&"gBc-@9@oR5J1"lM"Ie_\LgqSIi[0V*\,QT/R
	aoQ%jIC:g%*5s4ZV_N+HNF1>9o/ucSi/]m//rJ=m.f,1g78Ff#`9:g:VF:%X,.O_I.4F1@5t>3Q
	S!$EMRijoL/qdYAkVZ,Q5lpb/oJeN+3"KnCc)V#kZ,V<Qj#r\\-N]:i3Wb@ti]8UA;j5+<5stEV
	-6bEUU-m]p^8[]+pEH6Nuf?dYeCD2%-s3@YS*J3>&PbMS/Vti-WnVme//9bN6PcKp:t&gJ])S<G
	UecG#ob*L0,%Nia5MLO],n4WG$U)gGaq;$;GFQBdAd,`KA1&RRl6):H/J9DKEd;fg`-B7GF`6j8
	LXYD`%>sDJ,P6L,$Yc&spJJEc!AH%g7EU%.kV6h$?JN4Sk>@(<fR0H@.b*Ph-^E4kGmr7Nr9h$G
	i2paWZmY*H6;$eb!-u^/`Csl**IQ?hgMS&!s`WC+SX6BdCWj<0Q'!qu4"*XHW7\cckhEg?0cb>J
	>Y8M&EgMZ4\1ZZ&$4#2IhiHe;d:!#IQpYP@j<`bgJ!+(F^0Q+Vp4&pJeT/*=$X1?k2sfO2j,G]/
	grr=,J[7E@K_6#Nr:u:8JjT-[W/nP,5`+G0<ObK=A<2Vj^\l6Yp[0Xo7@mH#g:;o#Br3JeoA\j,
	q/*N:oE5d@`Lrp^_63&'"<`Ir1`<:L2R:g!M<@o1B#jW'9F(A?j7t^rIHEc,SHD6L8RXL\/7ihe
	f6A(83n0Te>NA.jNu9o1!a#m!2KW1"M,'`2o*b57)cckl)QfmO<NJBrKdiqE2(u@5YRtm[_:Kf0
	).eXQi`*g"=^d;;E;hEUXa]`E$%6;.!+rg<>I#EPPI;</e"""unWY29#6d%4lXK"YEKQiTJ'p'>
	X+*D*mM+N]aj0(.Aj`TFIY6fo0qf*9T3(;REH;p,7U^*Js\aj'=U]EF57p_6lF8ei<as`l!c7nj
	_i>YWD>G!#&*ajZ@NF-7M\D]p7:6[U0^G6/lP-CphMh8+=H?W!WII\BVt&c2tT^$-!0hRd'N#Kq
	)(R51Rg@9d@o30mlm0]("R;Be>=YO#<m5<&&g*R52p)R2GkG<s7QR\)CQ>V\ll2H^Id2g.KpYZc
	)]0Z/R>FepTa7l2%>fpNA+QZHe,Oc,4K5,6^1NE'_ebd]AD!V_P)TC0t^i%E6a?Z:==>#@AoO/u
	0*RO%f8feuD84RPE^QBQjJ4,IhhZ8qq2?]I@Gf=!Wqm>\&73,UUa9m<W+KC7:SV(>_n%0Tn%eJ6
	RO1ak@4/1S3-3`ba>tQc8neiW41E4f#lnH'\_FK&C%@Ch&P-,I-m@C?U?;ofYX^`5>QY9:5?uYH
	kYa?!mn^p#KY9f^q%f/\7CM2pc]4r&7f2_dKs>f>f%E7!QiLH,j`<4H[W>RS>-Bio9XXli%p@(W
	*^7oSk6baZcJ@rr=0i1-[LYMVu+\9!/09$9K5i>a5qbDVB:q+P^8+WNG0n:K#Y2LphL]ICA-FF`
	ttDD.c4s3[kq#7WG!UTs9R9U+&_$WG,mfDo?uS5>p)*)b?:GCBhCn7@d!&)*A(63&pp<-]75Lq,
	P^a]<R94iB'"u8N]qhngh($8`l[.!Wr&`gPuT?\?&E'Bc7oTmkZdN3/I[EN`NVtJ2X^.r1o=_i:
	YB0/*o3)gAV3P,IP/QhPI>C/(s33dRG#;4*3$8i%[P8+2,te\B+_]ije;R[&r!FV[mt6#OtUK$<
	V(BrMJ^k51#9D(=OrGJD^MI4b+M$Y)#lB-8S\8SSEWaD<&6[jP7hmN]6'0OR^g&_)WulERM6ijB
	04I1`]0rS!BF"eLg1;J"EdN5b@79GfMeh.=k7C;D@.QRr##-eX_cEpl$p)nOgW<j*7Pb7iOq9`_
	Z&tPjWF8P,*F(!;bo`mRl=d><pHCc@kc6<QH/"T9[*:T(MA"U+*f&g;^E[aX8&^Nd``EE5MhX2!
	c`IS+/E.=`Q@D-='4agJ"@RW;cjK+-caBUQpPYP=PD-j1c%."/j2=>,sge[^nemocnW7obB(kQK
	W']>98p#Iau._d4S+=k*.`]FWAOI$;WeCilF?Aee5m>m@gP^-,-:OpilG+n>D*p%f9Dqfph/:O@
	ZBmpKJIboHLVdGqPtOWdPB>5DhWHR_n1Fe8:K,PfD1nVCVdnD69B1kQbpD=ZTJe%2@f-e,3dTC(
	d1RI&J%+VX!//5RO%Rc2t6IU_7tX!7lP'>GCR&eCt?PUCnMXh]D:(96ig.".lRJ(`r?3DB=Hcl*
	6%F328lB"hn<2/6Mma-h44HXAbS3'dFR@#>V[.-H65gSck(kJ5iHgor;O[A"RORP)o^aI6.=B<6
	2>:-,Hjr8D'r@EXqP)32XgMV.8PT>Q&U29o2L@T&K%ii&HlU,/tXf'Z_-:%cT^=F1O37gup<^#c
	A0S1ic&Ob9I&h*I/Ad0$M,c1W2q.cJEQuT>IC8.t8,D[_6IO_/D3]nL6D`*-10Ynu"%T8f[GR\7
	_K-XJIMrEK<u20V;+hHqg:!RZ$E2NF?mM+J/#X.;gGTJ?3Lga)WO*UTn8n"9NX"8k+^%[GW\NCO
	S.!=.]El:MhT0cLb;p#.B[4DB),.f.,j3]C6VT*$.f\lX;ZIcGCSZ@U7Uj@@b$U#(NILmS/^jo1
	ul_E_3Pk[$%@Z)!BO`ZqV-BK[=P;/0Xm+RqW!`n2;JFc$#h\4G'4+TH:W9-FIaGOHn#@2FS"o,\
	n=hmc_8_60_&7k<FNk1^t-Om?Z$(a]Fm?;VPXagk"[aQ9NiCl:m4mnXkSZkiK:]]CP(4XNd9EZG
	`eZ%.8>DhV[WF<U?.-bK1S\kEO\<h9FsfX\Y+o0`5M5]Qs#V[=(4UoW_tJ/a]_$BtW\I:mFJ9F-
	L'&/2iN6mV%Mu[=V`YkG[V$,.H.9+fERBT94Ocd65+r4/tJ:ZC&HZ2\D=r4<C'Z[8"'.cJY#-X8
	OPCQGKbIIgsH"gY!tr8(e'h+V"_+;28Gi0u1R,*O/>\4c)b4c$]uY[t/Jilhr+][9FY-;CO+`@s
	5g9$'%nB#6<g+0\NP]I2Q*J>E@Gn_`g,.$]BKH?HiqR.KIi6a!81t!Srm$HCeo@;er)>@Wn1^^q
	26)g))ZaV_=>;j<Gn43g7+DPLoV<<-q+/0$+Z!i4I"AN^e_uNI*%s5.(-IcD+#$qnu=:Q0j/WC)
	i3FkZT=#n\W3GJE%St?Bp.S(B4Bn*f]mu);NoAbQbJ`T!>3o%P'HWMt+Wm[8"d`E"?,;2E>hQP"
	ZrSLN2-`!87aP6*M7-!oe_GJ.,6V*B+=7.U6/D5*]iDe]KXL[d<"\;DW;2p45KgRUWN(l,tR8L-
	Y)o5&1ME0C5AHk!U.ZrG&mHTWCS$i;N!QXYbXl(;6N?rNqAG.cZZW<u5:&F3?Gc-sJZk4j]"9!9
	YRJQ.HgnRT^b>isuD_E?Cc\QKIVi'#_lgA1jd#%GmN5#E0SRK*tH'm^9/K@b,!#gbqk"dCCq9j-
	:oXF4VGCk,BL_fOgc7q6Um!CpcA!=!/6Ll/r$WiEaBaf;Lm)PgiSXm-HhtVtcTT7?5hmT2PoL<,
	6ZF4hb`CIKWVA`GY$I<1cP)oIkg1.Fr$tDrH==JWh?)b;>)r^bLSdkM2"t1pIbT[\i>KT)'B.i%
	<G4Uh<Wt/f]8C6Yj2jFt@!65E/IiPNX(*V9T`VnD/kRou2[[<n-58Gu?Y>/M5@J8L+bN1Ee?2\D
	48T`bS@`jK=W;,\$,nm6:s>\(82C^Lu"jQ!lf9`fG)eb9@f!FpF;R`]ZgLa&04u^"Lj;X^lF#3m
	loTD/LR@\BO6:q!3MsY<n2LU3W$^RuuagAJQ3&&I)d$m65TMj9G?"\0%hq/uC:$OXGZ,Jb@n8'#
	msh0i3LRZk8Qd4-i*teqn4V86oSbc1oA\hIsEAg`]uC!2#Gp;(XC]>.*R5?8QA<oAKMcB9(j+`3
	t,)0NA-a=X(uJej9,_8R7m-d9Q,=h[Pn8V(upk#hkJZl0Oe:[EH-MM`\Fdg>V&#LcS5WZcEX=^]
	YXISr>bY@9g:?as!u&b9u!@L5jT24\U_=kH7)qnY&G=:0'fQL4Ue191bR*R(R6S%gT;:m6aZ]?2
	GE8=Y8LDiV58IoV/5!r6+?,:cFifJ<&RKK8nRB%.pK)la(.[FaG+ae;rR#[.+=uj4i30<AoYaRD
	Tao]-nO]1@<,WAuM8]CpWp$rNQj0f?&.Sgrr/Ecs8CDUBfla_X1>Gk@j%U9lbS"2.NE8h)!H$h\
	\^tB47TLQS\XAVcsmf/LEn5#a#FZ<pBYo`_S-h\`6HPan5"<.[F+*b-s>+PhmhqHTeNt-:`>tmD
	Q:LVU#aJS/()tV^*@#)YIq6A'MU?lE"prg!b)u29k6Z\W-\E@PP`bA]W#Ja;osfH"_rdh=N8nad
	:!Zl.UjHEQ`Q9$H4O&!s#;H%o18K*UkJ9'Q0#'7jk9uUs*]K(683"Z/:rlS@@qI:bot]i#qR9W9
	9Ue`MUiiM:s0+V7sJ[boOaNW_Sk#jX!e2=#e8(i,db<ZdB+]>+T`7?,JEb4f-Rie/MS9j^#g-Id
	RCunh:SLEcY6[/_o@b,3fuJIAUdHenmP,L7^)>\\dh?%L,_RO(24I3r]35qnXed=@K;[VN"XEmG
	(;B6)/rT@iUK$P.;k0e!sAt7P!>,Uu_L(IA`p^V0I@&hqNT0&]Uio"BO*Z7jO9QiC=?.e%)Uf8l
	D!-1U0@shIh`3h\rme'3K!Vn;]oJIY.`rR5F[O=b8RLRGSET@D5aWg]q)*C,TeLEa-qeHCr%b%V
	aYjTrC<nUN:N%ZSC7j7;23_3,YEmM/3g+5$t2lZ`>F9D&5qsp+a94R$UWR>8q[40dBTu!W\3Hi%
	MV+htW1J9B!M<`i$eQa,K@fi"mm6g%iFf[WUPi6%FFQ6gSmheteiPO5R]M=*nq^fKQ&MW#>">pF
	%u"q(`F8#fio)ih=\`DGlJ>g;i,#T>hdtSuJa/IZrMX,ar76FP.U&GE;f%\97+gN:U1IZZ1.FKf
	#U.HOmrnJRRK5=l8T7p=]1gTJtX=8<L(SQiT_[crVf!mo^UYGE(;=^U.S1T2X3MK(JBhd6+Ic+S
	g[#q.7ZSR3&p'?!)7;Z^S5pOlB<sb"2mAR,!/\A35S,NdVF1lEQJ8EGQqW]r\q9i0e&;-4Bo<Ei
	4Q^5,Nij]0?A5Wq_oSdh:q_4mkoK<'hKci:$6W?uaZ#3#tF8.j:kHoL8O*iS-A([(/\ajrtCseX
	;U0<"]_f_<.Y`]kgb"=q-hVXc+`-hU]_D*S)TOV#LG/=HCgt[5I/D.Eu.G)UU,o!@7M@YhXkn(!
	1m=pWFNueu`*?:>-XABT$bcWiE)3"],1@5UhT0Tk^0%ahs._3&HL7%CBih^q]<c(q1P,Z.'9Jm3
	7sZnZq,gn"J(n;TE8d;YYYgbdqrpn2TJtE'3@+pHNm5`6ao():oPsNl?'fUc%4JH'6$UT5aJUfP
	eYA=>!q,r-rVf]5=b5YdtiU=Pa9]rr<'BrcKhPgnc7F]J8s2?aD5W<eFA2#Pu!,&i]")Z?0LN)C
	gn?D/K/<g9V'go]`YA/Jo>fe!eD*m*.\kF/.2J.sP::7)p:QfZ66mgnk(l]gJ\C?SknBes?&uHQ
	0J4SVj_VRC&7WIgUC8FA9@aSh]`"`S<AqejArYF:__^lk4n2*.aW3%;?]WRUeCiguU*d$[><;ns
	JYnDNX@Vm'Bs>/T;dXg*V6'Oui-Mn\n4s?0#p+[ZdUl=iY@POQjA3(YKNk+u,_"'9$<?Ss90[l`
	%:7EG_LrDYEr#GjMNjM["Hr!G";8qNeqpC0[k5.7WJ*GG&2c_'H6\(2?#Qqb/&9Z:=`@7tq.9X?
	q\YOe,?f36aLHdm/QRH4TosH48XPQ5rV(3jk21M(5Xl[qCC=#cTHGTn*W0G@Y*E3`di?bii-a*e
	!Q'j*enaG]FfD=jaT*YJ5KDYV)Ai/R^28_NsJsB-fKJYQu1>!1KdoZP).p@sG?Ra0X<nB`'[F>t
	7eUh3p11:S'M]^j/=?gNOA[BK\)p3,,-78T'Q#0A6rr<k%''eN^;1]g#,?&j*-UMj+gPAiOht_3
	+9>W5'K.,<".EM-Ht5p_Qu]0!uSi.kA:^Ci7,3DXR'$ic\8_/!9pLIGe0GLMG[D]QGr+Zd>t*XS
	A+0p1^^Qrr<L(AHSiq/2hDlLrBX2=Oi6ZEWBU/\N/u5c"^0;Nu@`/'1`O\eMZucTBP-:5$Fmcg;
	163\?F8"8%i,j90c?[:3t7F_V48*OU0P(9@I$I8<<3J:)KC+A)OCHFhn4TkUW-4T];^?B_MESP'
	u;_qb3/b6+a02PFVC?X1bqtZ.aFU_&#-kMP[hhL1qmGq4.98Yer[]()STNF.R^/MG0KaV7cS5#,
	Hr*,;uj.moG;C[V$F=fVp%;-lFuIj)/VBag'4WrX$'^F[@\=\$:ot]I)<:DJ9+B$R#Lm"7X<F>_
	gIEH8gU*d,\mlm,>9'h_;K^@!dpKGQ.Zp=h,<BFOiKIc)bb41Of#&F+]X*cVm\]lu[D)4Le4f?a
	eI_Cj%j$/LeLWIbYFK<c1>OCFUfQ"_LV<meg7K'JjnM`DTbNFu-Nh;WT-8>EuWj$l&cOlc!%blq
	;0Q29uk@?L'n+h_]=B'nSk1!lT3#%g7p#Zr0P+)e@Pa1"9LFL@4%H^`.Ukof[$[Y//?.<K2!'L8
	=-5"JG9M$^4+kK`Ec0!3(=E-(A^Qk.."@Li)2/hiD/.aVD033U:dRGPut\4\F,!m#u@n>5nScq3
	eS2id8oJP1*4U;mTe&dn0Q>I%UIgB"CmV_rHuXkcDN>IfkR+bUS)P&VBUk^U\(RPb5km0ULoc-F
	JX-R'cCEeCLZ4JRA!0^KDQF$^o1FX<m*Apa'(MD]N#/f)"6oHjB.G>AVXF.ofe+T>aQ&oQN!T+#
	g+!.n3jM\)^M<(jLs+5Ogo+gH5S?esuWeHfLa\.oh5=fDbhpXflGPAFgda)u]49Vg,iR!+1;fU3
	NG'nM%qAg:Y=e"8oG8p^-9]B"2X8/)e7"*BWmV9J/O=N;a7YmBc\L7XtZF9:gipGB*FU(/`=[e;
	7j[>(a9BOd@;3`ug"W73(]bB!JJp6`?@b1UW7_Bg1`cFnb`Zf#fG:5%^4G$p'*`e"`"#W0Ic6;=
	g=M+Ffn]?^FeVoJS7L%*NWQJ(j>,8B\ne6%<9En3:*ui]i[T;>t&$GRm*gh;aP_$:b:ndH<OMf-
	E$2;sbqcZsP([5h*/j$YU;g<Rf!QPR9fegOZu,/dHh9*n6FP-d%"=79u=IIPZa^=Y)ZUVqpWkD8
	k_#V7L48fHZ(ej!+f3.\/b/C-*'..;8n3Ho5g<%Z:M(g=_t@>"-p"0uOAYg'Pq\4\<cVf//gVYP
	FYVnuFOLM7&2<[nA$8X<Y8mP$BHUaSu6r.307c!B:0,p;L!>D0HYc7X/R&Hp+4W[H)N^D6<,&cE
	]"HKjoaGabgqb*&bb`-,-;*]:b[rd2]KU=6e++Qq-(A$`r'&I>[#d>2iS*hQJ0$j+'@M$n*>#.Y
	6hhnV=K:R;Sq/NR'?/r*;*K2u43D6Yp.RhSf5cL>A'Z_#-tgc$Br!DPmX&?#=Y:eJ4t4mG&879,
	#Aj,:,ki_g?t4X.uB2Y$a][l2&rIW.!+1)O2BoTALiR`f#IQ(4:1u]GdB&$:c/T)2!=m<Pi9Vla
	6YUS%@+J/lus9P5(0t]DhjBHoKXD/Z))-()<FnXoT3UlKCaP<hj;LFF6^)hse@:W,$];T7(ntE*
	cdRUpERTKTM/%l^CQ538L@)Z1r`do%oe;A7_1W5`r$OVor("3WB(l5E/H"7<5h:nY^tJdl\5Ebe
	(g@>PY5C9/'mfE(2U/XU9OJ#t*N]2m)@HRVn#ujH,ksGA-JI&aV%S"J3-L+,Hf]I7B]>p@$\h^f
	UAnL+]mI>[6!jb`;q7/KpLNIMpe#NS,[m#GsPGdt4u35#dQr<:7;bWu&Z:2c8&KSti!]N9t[6g+
	I7j/MW4T)]<&/54/YL-lBoN;6<dDI#7(7i:#iC'AqN5Sa@,SY',c5-YH1Mb#E]=B'A:?G@(LGSQ
	=RMD=6P=lj7Fu4QqFZO:qQn0$jt:Q%9h9B^R>qPP#i1B8ug0%\Up]A.uc$QdK)B3!`&:JQW<*;F
	_`f("!mJ/$s?=8NS7rZI80i::0n0dnM;UaduL6,Em]hdEVgb9e5Q?I(Pr0Pn`WDH^eY%1hQ55D2
	U%,AcZ@e@iT".dcFf`r^M@bn@+h)CDHs>XQ"??"LG=hM_P2Hg/k-jGNiB?$)Ypp]8Vn.r-*-t@A
	h>,P2*qD`tFD]AhJ=9H4c1&cBCb:2`@S"?$J^/4@,kh]rGdJ[h6Fsq\(*)HNA^tADlM#qpKB)j%
	ESu=83Tj4f?1N$Yf.`B]&<Cl]X*Y7<PR\Ak-f9b]4Oe!crku)*'&Z_)dUOpRRI/@ie),X0uihCM
	Vo];oCCpbN7I17UerZiYI"pmu^3%BP&^6+"+0WDD>5XCS[Hj1pgO!9(:/[J$S4aiR_YP:q%klm^
	J,p@k?:YO?p\Fnu-SLQ.)u(P\k3+2Pp:39;D9F>?rRhXE<9-jY!__Qg[7;$njhi&-rN>,kpBbWi
	$fA*B'INhY=S!g/itNf.C#PDoD2*1t19;NHX[+2tr,G!6?1%R`[=)ZS#-Q\`B@qCnBY_f#eqUe"
	hRD@7tE\"[Q#MP&Nj4_>Cg6dotsW?530GCH^XG</GL$6E5pDJ-d**)?(1d!@%gektrps=rKjncV
	fZrZdLGJZQ"/_JJGa>4&nNH;+KqWqjQ`X/,oT[c`DB*_c).3)JSX'I'O])B\?.,'9YYsc7q\lMd
	=/7.uWo^CMb$-[ZJ2tKq^2[P(q[Gm_kWUVfm(Z1o_oP2doX"0t#;RijOsbZKhQq7k<BLM,nTM6c
	cB[>9%TAoc3h[<<_gIk9YC2/J7TWVkm+bh`OJM+sJHt?fk4<Mu[mDY.#>e`htR@c(N/;)'siP4K
	qpM5:`oYREse%iDFZ#T0RcRpg']Zq?Dq^c#"c`X`1,s\<u[k,Qhf$VkF*@>`A?pEE&mlS9c2PJk
	8/'Xj;Xef>TZb(=:.6FH$Nj$Sc6DYU^:<q8QB`ZoI6Q8oL&%`mVST9j9u>>H.#@dRI</r1h)jeU
	NC*!)O!A1\As%CDf3=c0dl;iHqt_7jK:*69aMJmp,`=l1c0EbFhtZ\G1-B:5uesZ@([drphalLB
	N'K8u"`77U=W_9;b*m,dtEo8EAM)!;FZ:HWAZ`E^#7?IGkW.8nJaibm5EKN.LfsX]2%gA2Mm!H[
	AlEi_@L?iu&Ob9\Hh2.sT0:)i%>/VCEK6j(?a,[1)l9.^A/a7gK%oY<m(6F-uJ>_s8=R"M;'Gd(
	H0ljcpAR/3+f'W_sL#$`S@Y:spW\1q*:/6#bEL/-N_=`Z+FjrFt[p`b(e$#u]`a:2QgpZ/BRg+o
	2[=Iako#9\bD"o2SrHpAb4_+g^Wicfmp7CY@u!AiQ2qV>JDZ1i,\Brd%O.16L+$*tgGJ.bcke(B
	M(48AqShi.IVhp8N%*V'_0]IP?#3,f=@/b'5JCg8<?>!.prCfu1(.,APumjn,6qe"Z)n&V>D<8-
	5(7oHSq:rcLEL/VhX.j^Y?9$XJi@V=<qK5%Lq@dXhOe6%i`u&'?qZG-'LMods0*G4E>!G=Kgo8L
	&ZA6B'Q5k<AZ(rr=ND'<tfigup>;CZ3IX([SX#g+*]#bI7fiB/g5tJ2?e=lVYb#&".W$:\[ie%C
	imtb[)Q?me'5*E@o`5<n#+t*4i<:e,[DqStd8HQr[uq(!O-@FYDEGf2C(WNeQI@Cim)A+bhL4ba
	XW3A6AqN]]=)e32W.&]*A(rMY$hh)M6XGf]h69[Bm-H+!a'_IUBaCjs+k.j:47\T/eJEOU&a/8h
	D\lZtm9FN%r9[c^0P5!5el2&pVGn0Mbl$d9=EKe6O`c[?[TGR<9n2k%4e"B=QdH4DjcS)<r\sf^
	)&-Hm[EeX\(%%RS@L4hrrG,aAl<MGoZQ@IuR*i/LGQT*spo6RM<?AJi4#bORM$6"if!(%s*r]T1
	[E-MtJg-IMgnKr3m+DEkIFV9/;(?oG)Qm];Kl`k/p(@CZVQSn574R!.+NdVp$Y31O*ud=PU]D;F
	YV)(&W&ER!(<.mfGecjI!kO2uujGHAn;J16bN.r'+g2(lb.0hJ@XmUR@@0/LHs((ubhAe7\U,h2
	HF5%B5%g72V[$?^+AB.uF22-Q+`d-HnVQbgtm2bJe5'1M7r54j;Qp@[P.u.o[aaCIo_4ZFL4%8a
	"O#<X@=<).F,LU>e>\:2>g@O_=erW<)%U!uqIe)0'^,PU9Pg7YA8?oW!j]2e\ps35Jop^qK8SN_
	8"JNIS\caZkPqmtME+B$WM_aZUc*_geXm\_At3T1JR7d^hFf6#)P,m42.^2Tmf/CMCqLU%N?oXI
	QN`HQ"<l<nB"ZlWTR9!rC>:,4>=^_tk:k<+se\*3@GAf<%jDOh*KRDP=dt9*9rJ_'=OpNH!#qKB
	87Z#Ym5n1g/(JQf7(nYHaTeCbNgZGA9%G5,8Z!oCoFa%@G_aqmY^KApDtPUCW:WdcI+m/Kam4lV
	e;2`*/de0;?nm:dhb_S[R7XO-0C5d/0D_F4RrQ@Ar2DlX9@#GlIc+k>B6.0GP?F0\&CBI35Zcle
	LhQKoQM%8%Gf<1[/c/VfScTE]00d]iV/7'Ug2bjsHe[fV_ba,U%0K$^4bo`bpp[l96);*RX,<=*
	@Xsa4_YqI,[4?7N65j`bS=]ooU6&dO!3K_;ZIK9/a8GZ<YIQQ^j6To`K`@Z<'37GfLh>B&P+ZN?
	c[_WKj3&G>PTqFWGMo;`[%M'=52q_"QnE0S<fZmPlJ`gf&5f.&Co/mrn&3C-F,oDPrgme=J6e=\
	q,cMVO3L*ZO5Zi:70<lUijrY-\n@)qjM!\l8a_:50-\$XGe-(e\G,)h+J^)6B</]6?,0G1sp6oU
	D8Ch'A(-Un/.&)#Qj;3MaQTR/3/&2&kB12$ad(GUQ?FU9,0Wc-hg@EH_?^!qd)kq6^O:BIA`?O?
	k''Yq'kUE&hAl+c>%?;=%i_dX=mj!<*NQ(4p?*d7?qW2`dNIpBRm"CB\!b?H0.#jgEBKgYja/^5
	7&E\r8r<O@i7eDFYei$Ku`5o-\%5@4%`!c=+EeC,90dFY9Y(-=,mW;=h0bN8h5@jE_t#*;b`)rL
	BdKqFeH&9%I-5?:k4$[i*74&P;"-r1tqiQeEC\Ia6O`]uHZi\$g/IAIXg+P:&RRj@H'3EU:WJP2
	>;V4ortK.Q-UUM3*Hh'68GCqU@W*ltWcN\Zol<?>EM?>O-9h18m_8XPP6eL5LUh9<ijg.!IPm%c
	)0ANDJ+A@_IE^:H-/T-&&(/MdhXA8sCS4HP&p*Y/Brd\XL86['GRPgK;[MWUeb$/!W+3#EB(enL
	a/T6H;G8L:'`6.7TYP(e9Qo>C#ro&L-Ck<?-/I=ZOI5Ztc?]Zt'R&h/GJ-2-;U7/6Ng\a0M4_X7
	WIdYj=ldT5tB<p^q6".,$gamA4`jD:B`(STFeW(c]i2#-7&*pea5lqiKM/$GY%-dLBO>inMV<!m
	_N/q8P*fEI^%.X6VKU<(GL#I2SfYr$8nbnGSWG]n/nhI-0C?.]=_J<=?\%&&t,Z8P-O-9X(ZkC1
	ULp(;>^N'49HWlk-X4YJ*G@osj]MGW@sagJ<H'Q<"e5IqW"Hb/&kSgjbjAouOSKA:7'nh&2Pd!U
	lns&e"RV.^FY'o?K/Hg9auGV/%k9?ma^Y7Llj'1[80CY9Q]B=iY"A.QWf7_1t+-^GQN>*g&K.KU
	Q)cg9COBHp=Oma^]=5F*n!dpJ!T45mJO4"Y)3Gf-\&b.T/<.)(j0)f";dPjfl"Y96kBuM`LB/Lb
	>SMJ_9TWo3CgaUT(o*\"TGQmtEI[0gI$umZnPu93DWb$('K=WU)\TEQqI`-aG$qCT4;0GWo>![V
	M8+S'COl7[k,UP]jk2mV=gW4]3mdB[bR\5&]G>7jMhK@kJ)/WJ'ZL;MFg(?!#tF2r!DPg5Coj,"
	`il*$1qH?9#tJH<3G9AaGh.fAV"'?i+1'8/h:;&]UKc)R_B4joZt5O0'd4>Es"3QFtK-9;_VN]W
	ni*2P?Xho!FQ8K>pZ*39M@TSQ+I`<8(QAm62KS(+Z>cV:9215P!Cf8L6KL%gP'7Duot=)LgBmf0
	oKb/(j&B^BgAO(ne@(.,g$a$u(;Y_e1>[:3f'&;!N*9WO+lVn>,nsqNFKn$RN^2,-!(/+u$*J*"
	J40<BF=dBj17A)V9P0<kPlNH/abKiO3UZeFY^;pT'!Z'\/#=6-Z<Kbk9lHp?,MJk&!H0A1U8k)\
	N/sOj^hT[3!@D_T?pVJ)QkE-Za#<@FlVY@R6O\nOM/s@fEJ^kFqZDiRXj!g1X;UW^f*P]SoboBN
	u'!.*#dW-e-a)lDMkn\^;<i>@!65=2MFE>!Ve*CCJeB/;YnF+d<YR#TWrfa'9T*eXEG?W\)\Cd?
	3^c#b($OCR)TP`%:dV;AGIP6]Y!Q'\-a$Yqi-3[k1>5.HclI"i<\8&"@=pOua(C9N(SAc.K43o[
	K'(!5WYKIrnP::_)DY9dNlNh'8N(ph(k8M'0Bi#98Huk-\3U;`@;?A?^;;;N5j)?GegMiIRimA'
	k`OXk?bHiI/G6pVih9gr;YX^oCD'#>4,9a1upGD=QFP+!5P,X^BXMp&td%"C;j-?2_(31!25NqT
	A/#Y^OT^i._$cIqW#:ro<\EVtHGN%q,9fhZIN%9M'MCa4)=9r2<_^\c\W&S@=B*ALP2iDIU8gZ]
	h9>J9@,25o<ucN/jGXrFpF&lL2:&O4aI4`-*n.+RqUI_4R(<MF)=H<uCk7]M*YWYa9B$5@r^a7d
	O3pH<Qs"0ul$kcsu^ClS7`j@4p]4+1!$$_"kS(Poq;94;&=":!+1Bmo/nHp)gMebr^F.dp%\@Vd
	$Go[r9CN2un'tbKV]A8$QC??->n<4R3JCQWDQ]cWnF='?@&tntYLYY^72AZ"a)"C5BBJ7a!"s2m
	DQ7!Mo5tI0!2Y[%@DB6l7teR.o>1r`$SDHOne&\VmS70)NOb.UTOd,reJXNK<?\_9]Bg,;h'/P[
	&DV[a<A2+p3pIV7QBhmnL&he?QEk[KTLKWl/9WpMbJ!hNc*&<\[=XLQu)H6e6(KG>GHU]9FLbo/
	ET(r9>4lUmjIE$Ud$t)m5pD&q>-Y=FNCt.cutuoJ__G\ZQr`#9=$O2$F]_/Rt=X5CrGaC"S`/94
	a-Yn25D:_M^)KcUq7ZJZ[p$_Z4c4XVYA?Z:DAHO@N\5;EKmOYo!MIH]^aKj4.7kb]!_/OfXHcOb
	<>((F3AnYbVG*&@"7ZHW:\X\[E![EQ(gb1L!Eg-Q2WX\?',rBo8,4/cdsm'krKI\C'4IS?MOa\6
	/DlC?I"5>;WE:Aa*)L/<Ze@[$!+2?<N=T6;C;!ECs)[Eg+jS];Y(uUn1m)8)err`\):/5rgE7Eb
	?=BQ[U*l_Pq/H'H_H&q<qY$:rC1L_eu=uH@NgNGBR.;K=$Pr>JqG>XdtHOH'@(@bcoj=^9#OD"5
	K@:Wa_eV,GI=n=?&fRlHbps>Q4[,2#(FUlE]WG&%$6fr)hLD4%p\,diMTlrrB3T%$,O3*qdJ+HF
	(:1Q'%6e[hm'=N(n$`,l#cgqW<.AOqI]^O[s"@hsaTn"2_P3BCSXR=-#N^mU2Z%e26bS\tA`$N(
	;8i!.@`6]AiR9r\E\EgO9Ct-Ca!F#03,`N1dgrZH/Ok2mWKuh6M<(f^+LYXU0]=3jt/dX]S;1Gm
	_l9.)R9Z1$D-0FAf/#1K/q47l>T,nJ'e/Wp-%_L8DHMp833rW&mcr_^:ptrFLe-N;imb^WO5`8q
	nO^f'+],P3i)B1W@1&V@p)^CHJZVql\8iIRd)s5l#[$=-S'.BbC/'O)SijYtfWV3$%`>1-*23eL
	0E.H(=T)D.BHcA1hDa0nhERKfJ?/Ikt9*hLm_Jk5HOT/n`]IGRbcK9$H<J`:Wm:DpQkCTbV>_o9
	WEJi#O^KNu)#+cK89V9-KFP?&;g,h0h9I:9Bd>74i7!fqEpG(N*#Po1qWXD][Em8V/6+bor:fTX
	JpiP8YGb^`Ujb!Yle?:kqT5e,[Ho%0-g)r+H,.4Q-'4"4U3cV.^\GBa@^:H;H[0,U7J'aW@h+`*
	tW&EnOdK"c$Rm1^K=(mQ8i6Uhq0ee-lIW5@T<B;5gi5gT-J.k8c?I_Sa+5rl0kMLt^]N3C?6P^s
	KO,0O$]F7Dd$>Ln&+<3N9P[IgT!GI450H_/Mk)EbU'G\MPHb*gK&+NP^7&'0-1l".,PI5<8d9-,
	V5/qMG9=17X@\d#(($KaMh9bm51ea!Zb=Cdo(#@-2tl1@82q\3#14P)6iTh&,b5@\f_HgW^51__
	92ar9<PoWA9!s%XM"ii1OUW">[td8GoHCKRm)GKa2>m61WAGGA"Sk)TitK+u'FK!"eZh^eo!1pO
	N0U>RK(h+-,7p7PR.%PZ-]P)6]mmg$ldJ^YVid.Hn]*2^IrSrFpg8n_YSV.0/9.GK?E`&NqQDL#
	^o"Fl>JNH0-ss+i$'F_[$#:Ffd5BLoKmMb,oLgNo]C#TP*o"erEt(RU21.b,H(Km,s'rkOJh`Cn
	u9D++^=9?M0;hJ'Tuhc@3H\F3:CjFUmSMD/B`867=&a4U4pR9jtc;dpcbjc->hpp?t8hd-kEOn^
	M]YoH\P"9!/X.BM8[i&b=trC4MO<=tu5_2'Wt3i"A<7RUWLQfG5flKo(p!W9!*&a#%@o"QkdT&I
	#(OYh)S@TEpG(&K;iL!>EI%Lo3,/I.<)i_T#<iM&_\E3NXo*eLUko?c'.ZM,d*B`_M/DL/F#0?%
	9^]XA:>;VWlNrUHPKa+*kQ:F<Bm\p(cC]+',23r].$o..giLGN=%VVtJ3X9AkH.o9WPC*LE>S6(
	T66FY-?/3Y13FS'raqq@DaY*CcSY<^gJ&Wmk!WEdo%B2>C8H@eae[i[o;LS_;TJb>,HNf6X"BJ#
	e/9lHI<<;3HA*qR'm8=(e:#P\A(Xq=DL2ZDW\sC@,'J`r?%GQ0e4U0QD*.r%6AM)Cm<P4K5u9+f
	1MG7WL;:8)+t$T3h:S^tp.-H_J9NpgZ^rcnr6t<4(+kOpK&jPRO1*blDVn5S^[i.aM;'R`eR8K)
	3c(fe'n]9-eDhN3!:0lTcO8Hrp=JJpV4C=,7C*++RP5T*YE?gL`j6`0$m'G;2es+]Z)oTWb@:TE
	De(Q[`aS^P\JGYOMPliXUnH!!lrNrr<M,)Qni=rRKDF!I&:!GJr/>Jp-Q!,S4Vkg:Tf5NB>"gXb
	EXQ^=(m8.1Pm0h"cTt)#jRB,6S[rkFO3E`b)S3'rfX"qlu`M?Y98/D_($=P#"to'PQm6l(RK8(\
	Z-,D'\b9H4QbZWV/4A\4Z%VrU5JE5=b]WS/C$CX\SB\j/dZ1q<Z9_G=eacgYG=QP=DhXHAmgCnE
	K^KF+^AL#LM=m795pn/Xj2Q*^T3D;_68-at["-%44:/4B8R>*:C)0L>V+oju4pOHZeZIXeO&#]:
	NBh'pdG2pJKubd#<BuY/k?ubo4:s=f1^PP*/;ejYA;7"$:s:PO8;3X`%gmUOQskB<e7WO/E&l_p
	T8AahVK'a%@q'?GrKfK.'%^dM^;STAkWY]ENWkVhmN?U1b?A8*7bpWMi7%ng8@e<S.p>#fuE`j%
	a[H0l0T^O2UBbd_7^=3:R15Fuiuk]J4n_.170([]s`@3V3Y#,gbdTNik&'&uc,1B^A_or#RTEf!
	?ci`udo@Ylp6/D&e_`,!ucR?0%-"Wi-d\PL'?UBn>:D!"V;1^OtDY]PDHE57I>#DtVkK+LcpgkC
	mLr#pC>9.i\UUcQI4rl(/g$3:fa'(rj6LbEae[g4JIt9uit=::($W`X?8r$:?'NWqI.01Gcuk.F
	L<jiVW"`>eYtddO\o"DJpmJ7g`c.bXXt?kI!:h;gbk#K4ujB,JYB8Hlqlo8\!9_+lXM,`-+'1)g
	Q<Xq1OYGJ-O`aLBJ]mWg"l*g1nRG;4>.'c@i.B+0?]G.6n*["?frk#E_9e`/NusO?q/R;Ubm(i1
	6ZlF$L?g2E1`OP_OI5`.-KniNL*_)/0!anSa;%oUU&&#gcd4;FhC*[\M!fUdV<"J67hboGOdiLT
	+0(:lWmYQ"WKV13RKenMeL\LRnqEFgm'Ih\kY3=,?9<66.]Hku)dhf%V5^^>m$%W/W7K4N]]#k7
	m:>Vg*KgM\?(1SnJ0\<"aBURUR[\3p*!+=M<jrW*8GoC%nb`-<Ob"<al5H$?N0A@%2U7F/]L^RV
	p<p6R0L`&3MQ)$(<FN`4AFG1@iiWpX)[mJ%D^UD,UsKMS2P?qPK4Ni[EB$V_n>jB0[9HF.EEDo_
	`D'R-,Z\'m4@gdm^LNe1^55Z*C]rV4-Q*_FG4KXNYnhHCCd!;j)f6gEogW'9o&N./6`\^)caO[.
	F'B>gp+U+CQ7ql.7@FUCiTh<1FqLMRp00d:lU=NVfaod]H-I]f@NfC2F.<!SVNqRh84(hgs'eLl
	kWWahc7`OkuDafN9,tAoiP7iCSuq\&qim7PiVWaEFm<$.SN;Wq@X-%D89.X[tkITF,^Sek:5\6[
	<RY7"OD:Qd!S4I(@L*KWWL9#]bplI7IO:'td6ldNh\gb<1^u5kQDl-qUmY2UYZ;(>$"HaBmHW)j
	CR2ToiR^l&\Uu(ELkd:M)dU7LhDR1)[!I#bG10=JLjK]?%fg<"+p]kQ('G-Jae9V5lVK"8l$cQc
	-tKAFQdYCc1:ZO@O8+UtfHiS7E0@%Ls":K7dH0n?qc:<M8B$k;<ZJ$r,OqWEZXVmPW.0%SW<Y(2
	70`5kbr4!Y^+43'^9:9aNba#1D&-`+g;[7jd>+OAt9Q;Z+T!5Kds-,O%a2;sG8a`h:larlqhOf%
	F\33.J_bT@1..RZB=s]:!`Wr3obo''Sm=9J^niZ4)ej/n1nIg3WpS",$R9ch+,SYc2=^J&90Sg0
	U"K$GIY3-.I#egN_akBd;=5n_A>hK1]n>9fEkuR*kmNq,7T<DkCYIm."Sh]-$6$)W"J@(e,Okk>
	0Ro[(,g5_Q`4&"6MgHeCQOHH^tII@efa8EMtGY^D).LIg8(Ji[meif6h^NVe\>8c#7lBn6@]%f;
	b"=OiO^aZD1;il"Ef>h"@d&<4CKOb=t=G;/p#g$=#kHJcq4IL/o2TO?re[*JuE7b?thUTLYDt9D
	ta%(ORIt!76+%isSQl=7R!b>0RK$hHLU-ZA?DhVnZup2!6`@XT@*mG!6'!Y(Q7'_U`$=nA_4EXe
	K.i2YW=a.`o)U[K?MSAL!>kZ]]<OH\,>KhO)8t$d1A`'JZS2G@7GDFX3Q2hNc6giP$oB[lt(B2Z
	?o2h]LM,>t2e=1q9Bq$@@BP.kg3m.Q&NPM(VY29qR2j[<KJPMDsd.iSPYiQPtg<&_UG*[%5O;Un
	LF'@@C)j;AunKVmAO-b,fJ\L"XF,Knbhdi\I;!#*hE/DKI<"$[:0=XeWOt_.3a`iHAd($MI@pJ3
	MKLm='RlB`A&>@NoLU9LNd*!F=9D&2NiV,/q7X=6:LQ\Fqr4qj*CQI;0ZW;DUFJY-s&C];p`Pj6
	=@2gj7')$i+rC/$fCF@OoGRpf=TG*#Xb_iNUb#4t!)tH6ZM/>!.*8LLmC(aL@*Y+7D-h5D^Z;-7
	6(;<g?b:rrBqWQqTQXd"N>/?]SR4T&.R@/oL+4O"sc5a7r_srr?3'VbtSkK%V*[P)SK]]DR_QrW
	VN+p8duYX*ep=!P7c5L$n-Nqu^@UbXBJ*DKSWp/FEk=lke2<X:BmL0E;)pa%?><rFc3e$0)5?(H
	bLpS59I8hmO'2bt#a!DO'`R^ep"sM]N'M:snE]@-S<+>&?H.IH6YPJ.G+/i%^l7mnMCjT@uNf/t
	:i0,r9>>C!l3(@JOSJgRX,uV-q]CTs"\`bLU<VWJ@pj](K71o(eD-o1$_9m.9`cI6esm)O,s=[m
	MI2\]Y[/H8FlrW:n="?P1,Bh!:l)@NF6(j6>,Z/tQC('W6G'T$7_OG-Uj_0%A&u;;3@[qNG9h8k
	s9j\A:IOa'hTiN2^n][4L)UjIX5jC*n#U]ZOUd-WFC;^#]KjH4&Lf\Wbc8SCR"]Tp]MV&HdRq;S
	.JPmS?.5c"e,4N2<O,GX"ts4\/2f>$1s>47HM8Yk/W0GE%HVP*O>S!G0RY\@+I)k$?)jH;u+CM@
	(C8'Z>H*J&,>uo6rOk&3B5XTG9Tch8s!c>GX>;h"#IB'N6O]eR.fArr<9$$2?#jj*_``Qdahr9l
	>SZeY@a5?=PJPN1^E#"Ligoo]oM4`mh+hfsIh1fN;%LcC7#7rr@Xmpts"r3;o1c>Mg(L4ll;qQW
	=mR[k:@<>/\3"Aj:W[=Y`c@)<kI.2DKntU3[Yj3DrS;]P7BG"Ut/Hi2qH6,&\/kWnbDP3Mk-iA@
	d@N#6]=02RYj'-CcbLM6!S4=Lp51E]VDB?c$0Y(W"p39CR^s9R8=k"eFcSMmQbXVjDt_6(#iU%R
	;=3a'@1e9++TW7oe?mnZN<hkg,@_%u-^_=,Ed%4?)2j)Yf(RnV>#<YI/_ZG>HZ0?/,g#h_^M&a0
	EcBNM1]HUEJ0`.[ZU$.A^`mjf-8!cu.6Wa6u!G0AE@*rNjsZPN!(e-c,8[#5]VjWr\.FH[k)1DV
	trYiuNEI^8H?9P^WQ3pa0?O[<oH2Vs,7Tn[H=qhnn#p,=elRC#IYrg>m"[J2YKI*2+W;"<GWM(s
	+bWF']NV2*Y_lGkI=m\F\TFa0a1f.2TdJ8&QpSJ&5-,BTDs+:qP1(MU7s5a@FB9fE#8U^g\Ljj7
	o!3)+IBD8(/#U6%<YZ`N7JB5r(!RbnC:O;DK+\i.;G)*G^8Xh!;MmHrg$#i899\&%pFTH)fP34s
	"f(o6n75=i5h"5l`5u_]roJ8BkjD'<*K\=(G''K"Ue@)?#g!0)j,Q"b%eCM0pQ<,@AplY7`gSFM
	30!BQX#O3A?_fDHCL`5gDi!\NBt#[N^_YX:ph!S[U`H2(2Ce;3q1,d.l:"'p4+t)%7!@*h_,FH:
	BiP]PX<h47MXo^Z'*:dmMOM(Ne8qOp$bcd!Ck$"W8\lWf/5_b8#1L8OZr]6c-2ppaC@%D1>hs1-
	ZYaRlftsmf*8_T&/.\EW350$9d,F]-W$H7<:GYb83K?b"&W4:ADZa%tjii:DNZ&=A'Y8jbabbL*
	sK4BliCo7L:2gS;o+cSN55e,Sm:Gk8J@&PL*rqr\=1<`nq3N`!mefCVL2aH],YJ)eflZ:_sbRQG
	>F#>B,[C`AphdB?8Z"WfV5`:IB`\rr?nSKDm"_<k75e*tugVLU8MtT[YTSRrY*!c:Eb-.Clo!H3
	93#X2<Fc;!$6o8%5C//*N%Orr?TEgU9lgr)3'5kJbc()SH%cQI8X-7sL2%U.b3A=)(3XWUdCI[h
	\2fn5cEW.-oCSnG'W?Wfki)lCYKIJc>^_Y8R7an><2FNui'4#/>RtAFHBu=\0lbNOq1dq/I;CM<
	.;63:%/5c\AEUKbkRr9n2)j@Ne'\;k);,YM4L`L].Voi5i^d(&U5q;33MPN)rI]hc,rd`tNTOO3
	%8'ps&\8r%n*OEt+b#Hq,3KV/QjJC"BN%c,iYA]Z,Je?4I?Q3&o0-e8WrRYMGu%X'V>=NL'PRrm
	G-a5!N3+al&d'7B+UF"'o&&)o6RsPCUmkJD3ZUE6-@O.aY.`rpa*4lU%Va*R<!M*[.lZQ\RG(F&
	6nC3c1t-F0Ou8'X>]n(o9ipX&P'<DV`%s<N-lnj\f;/J%5EsnA^1BrrCg2imsrIW+s*#g-(PhSB
	)UAD))<),DmnT2b7n5i1)ML[=4fIXqul_a[S4QqqLPrDs8@46CoPh`4"c@YJGBQoR@X+_)T)/iC
	j,!rrBhU/kc)\\OCd]Qg>AhF8ijY)6t'X!tFL`o-s2U$IP(m2!h?n<;`hD'mOc4)+JjSQZqbl][
	*girr@kd2o+;RBi=jqnR]Jh&eopjq.&)(r5td]Ua_TTocO`#c7@phiMpCfa^JoJgTpK9`hk)S#*
	`FDIm3>J_t\ZW>C8!sQ`e6#kh[Wg<Ocn->@1RUCt#lf:q-O_oZg7/FCI"aDAF;AUbqM1c?qfoK#
	LO=e"4:")rD3VBKlNF/b'jAKAq<#q_qNgN?s/eZV)Y<B.0ZuW<;8cEbh9XQX[4!h-)PE?>J'S`+
	Bj&/O`:=XP]4(a5]DO&b,\W#K)U[ILbl9L_Eb=m/0"r/BJ#M(dc69?P8L/YZMAG4gSId#;3sRnJ
	!M(KqdYAFn.ZMDEeS:KmFH0GppGmkC`cNIiEbIn6=kDMf(X[Y/@,bVcS[?![C>pfRRM6BF>A5S7
	$Zp]:Rr#(u"WBLQ=<Vo\[4<jETr,4?V_3<n/:2Ho1W1i=Ckc9U^`i[AYs-+^gKX!g:Dr5k2&e\a
	>N3g:epLK>_/oa^.*2q`HJdL,(m`--V6R'0\I%(Z=bFHs>SL>paoPh%d1(/FkGg_DDG$mRA\q\-
	u+jrk]-!meb,FA$FTIH[2H;^[<9?C[qE)^g@p*Q4F>tP1*@ANH`((h$q6)pUms9M"_bgSguJ5@(
	!0BQf7]QL!27'bpZ:FpHQ3JnNY(o!/KD<nWY(.f)/6VVg*gRb1U>U8X&:b_H8G<T2J-?ifu&!-F
	GLD:(>6LI0us5_pPE^<16^54\Q:qp:C#li\)"LLNMDjfup>;09[8uUduhr3!thSKI!,o3'FTR1W
	f1:l2+U^G5f'jEl0iP<2o5Z;.'1bH@La`9r.PG7(Ll+h+HEndqtFnf2n+@j$DEFpH8NAHWQV-Pj
	;%BV&Qnk*i2JjUDGtOa`fkn_S<M!_J^@Yd:iAXN3+0#B+`"I0hZDj1$B51:o']#4P-K4-c]&=[&
	HXOjSo3)bGC]dCJWX#U;+s%B<8^!cX4])K@`=:5A^:%o0WDX]LAgaf.UX4fu[_d(GYmPjBHks=<
	CuUI]JX\NEj%+QHoL1Rm/FKWlg?3.E?RLaWFo8\)Rpi`r?%kO2`4dM50rPBQHJ<>,V;&\ko+iqA
	pK'ZGO=FQ4;b.C33e;g3KIZkD`U1Wcb)M[IRrfrr<2LAcDaa2r[[S,tI\+FT2?EGcP^,C#WQ>jo
	&>;%c?RC^[lo1p)aoreXm/\/ZugOW;,CJ9DG$t.RGDK,AuJ32.Zo7kDJi0jV[9ep5l*;pO6bW;`
	2BhT-UG;rVlk[f5%je*qB71_`_IIm9=q0$gKca_Tf%4arN[kdBJb`QTTuDr&T#(8o^ne`'n_Dl)
	c%Sk]Kji/4L[VS(q`C]3+mLp-8&5_]OQc?]P%YUO5[d`GjR97!0HU[!R&!D,e-HAK[:KL*VeKE!
	J8mRE]P[/l\e"UWI_S^$a4;alm.eEN<-2DJo;.A:!Xpm9f@CgV\'ta2[fcBp%2!Pfjt;cI2+9[:
	@n#YbVms^s=@??gOk45I:'$qt*%LRGcRXVmKM#Sr%+>>?t1Ena"nEIBL_>+1GH7<`(D[5;<Zn,9
	n3uH*9BZEN/<fUV4D]*U9Aa5A;-<Y's;ud2s*P,lD5]d_&64rAJLG_c&CkUY3[$6YhdV]-d!87`
	-W0*;U(cYL[Y04<=`rN<d]cCVIRQ4V,[+$sk_,j&WJIL:6LL!!h$P9)(#2r#tPo$pW`AA&80FXp
	JI#@t3?Mrr@oTBBj_+pM,3:?]j<>\)55#;rLfqm5IDZ04.H)Hp]08f8uLo"fu*WKb%0q/?=oS)m
	RY7]K^q$.^Z5+=,]1c]oNOca3P,_1oWQ/J!*!'])@LK?)2i[*u"pg#h>]V)T1f4)m-t]O<8_72L
	N;qGo62lc$`i<g(VI(:QnHBhkg95F?WH&(*Y_6Y&jKkk-pZRpHGt_L-@P2?PksBgtM)G9ms0X2_
	/MmgRPsq/A%X#4kg"%T)1f9ReZ7D"Ul_$8s6PmYG:B2N^o)#1Cn68'Qj"R&#8jhCZc5''I"44ae
	/jo!%h^]@u>9^$==/s,PcYJpmTm'U<GW1lFVCNe2#E&W`]fk!)t`)kMbUkG;F`d9`.m3RcVWh"a
	cIuLEAkiDU7"NK-NSdr";e(U"FkZ1j.eRib(U1m$0p0W#>CSrr<3cAma86F3!thQ9Xi;X4P5g!"
	\4#4jUUP?jkVh5@a]n#2J"XYe^\']TU@j<>BC_,a6j\$*F\,nQDrB'RU5a@fG&LkNr<0>MTfV]U
	M[kGA/LdhUXS5FWICYI/V,L<=](;O@eK[Tg;UYH^RK-1]A*f^u#uX/*N;q[C2'-iU%uN"5D/*>a
	oo)#fpS6<M*tG#m3>ib7dV\gPJ5&X75<M'3jIipnOKqINl,,LVjoAn%I=pgSLJi@8E<,"9r!GI&
	iOP:347NGcH.na)UZ3T<.lYQ#35Z<dJn_)!rmu80LHC`DKSaJk75X!QjESNnrOE\ScpXIu3%ooR
	DPn!nR9PY>+*BH<%:V8k7`Y3*=e_R>=[&=B.gCD++PMeXql9$2q"(;5&Hf:%<F)GIX+<kcUaj)]
	auIfMcV#aFSMa[".m.m7N7XrL,a2XR:P^pig&nr)o\,g=DI0QeH&FDO4DU&KHWPE#DmN2<)6GAo
	:mrV?ANbBo&l8eKGJ9bu$D:MA2!j5*`P$;Udpj6S0:eN7d$4YJM2j=PE/FUgHrNO6^,\$$'IZ't
	g[CSd&a(VDAU8kiL%f8"h*IYF]CWUW,N7rr=%pr&XeC^*;lHF0p7Vl#1-HaDf"CQ<SUTpC/Mqkt
	kPFDh>_6m620\..Ej]lsgVnU1oqe>]II-#517Ijd>q6#'l!k4n31'rr<OX,Q%nsoGp>&=SSB*1$
	La#7Keq$[P;<i=;&:@>T*UYpp'@]i[;Z?NV>XAILb2uq@93p=iGmMT,?io_Wc0,Q^D04!d;[IN&
	T"s+$r3t5NBF!p4`I61j/?%LVuj3NS5D+Og_UT9i"*-$cudg$M%?ADDuK>g"8S-#HfdH(I)Y1ME
	_[6po3a%_;>bcADRHMa)YnrlLoWM/%H7$[uP.n'Z5MXb!n\=kG80#H7-NNO7p/fSTTAX8Y&2j3T
	HFbci+L!./`kX!qG[fQ.uBX*Aa,aqFQg,T:"f?5*Q*.rrBCOL>q\*h[hmnDEPTo9CXmYhOP#PfW
	D>T42?_8"d3SM*eKRX`oaru#l);W1acbcC@!W=kF%M:J);emq79QI=.[Q2d6aW*S(I.BT&2*uB@
	j>;Gilc;A$OVW(h<VYY/K+U>F=GK96B@]9d[a@b.G-lQp&_'J-&%mJcYPH'5Kp<:K&1d9TJu0c#
	tiG4@H60SN768ofUd8=H6VNBPAA.O&GT2!Jh.!;h[O5nnCjJm>sdYp"@$c@i3"_%>\:_A97h7Ve
	Tn-V+?SMSt5+sq.K^-"`'%?ps7kp(iF7&Ye_FRocUGb/cHa':EpnM7*bSVrr<2LnLqe`Kc8R%fA
	[O:^E/GJFU>,sZ^)@\J.%T_,7VF0Ql3n!.FZ>WUspB$EDHet(F:Taf2(+]<Uh1/':W=VCoqOGD,
	3aQXSaS*g.W^E-F0%5JV#N\cD^9A3olm6C)%#p(7jlphS%/SBhJs.Ze4WZ@Gf^qiGZ]=g&BmJ^+
	e$4f6(q>H^IaQ]p9D;8E;M*`j(Ztr4@f%o`H&s(q`jN<H*\L%h4;IWMrHpZd$6oT="M/rP(3S!,
	/jjC-!oTRYHZ>jRI4(!T],-"-(CLNdG?NCJ7a.iKW'&d?02ZSftp3T`'PNHVJ_XbOPS"IfR$a^!
	jCDCPX!kfctit=&Y,u5pM9"CZNB!Y9IrBp***(R*baHn3k%\;FBs,]K^?7!!lKg%;l')^/$E)(-
	Z,3gUDV2!1U)L>&OYlIsU"NPplTHQJ*A:r"Sg@IN)s-$pGGO?H;pZ_038r3g/.M1DnhQ2e$E>,j
	a>3!(k"iZ-/</k>HW4>]Y#:@1<h2ShPf7hB;ST#DG9%q_*2h7I_''`,5ENZJo)V,o]Li^UP=o\D
	?`:!OuVVY,GYa3Ls^4Ds<e@pS#a/2#EnfrrBknVt!/^Z]&'`MfcX*9V4f)/hCh5eDQK-50JVA!"
	K%`VFOM<!s>BEf^;gEn9^b(':De+f#%Fe_*EB<n7P5cGGNsj<j9<gkEb>XUfhC"ZM;"@bpsq[7i
	>2>al%mjj8ph7X1>]0:>q(PPV#`0nGT)o7Gs4AGUGefn=RL%;rM8&E!1LC`00p4n1lrjfWkMDE#
	:LmE#Y`5m:"O5h`X_Q,KR%GdW'uRcd\$.]2cJp5@o>!2cm;tpFW.1)4!bI`$7#i:OeX/IMMIaKk
	f(0\aIjhV%_j<paU3>[8.KaDt#^'`k6XM%P((&^Na`1\@J0)1GJ:&'ERHaorhRQMN'&b[_LmKfZ
	*#4d_:KZqbR4l_*1$tr&"ABHpOr\G[=KsO2H-JCH@a2o?$^cXK(M9D=S/34*CXZ.QJJL=F=shQ'
	.HW]%C2+VVHAccgZ2F;t3BU'6@:'[2Xk1K>ZP%ZEpj&9X.\@1FS&$7;$F_!X3af7QA?<<6f&89+
	'/3c`mELAVnod_)13Vao;?uIpV=nr)Zn\f2os>k.a9lMuNcgq(on&i0Z_<4?N(?iNL4=%X><Qrn
	5Z$D`!k/Z^+[O4!MhgEeG$V!UF$:K]PgFPT??m(c]O2AJm##%m0dkJq*\-n2J@jN.*_54Cd@6[>
	ch8dp@B'-D">XDt^St*2<Ra;F`(Ca4?e@7Dhpr@gjA+c;NfSl@7`dG-Pc=[HE(B?r7ZO)IAOGC:
	o6tG9@![?n#K5h.6H@jAmr4jrT=cgRYVL!!Nr'N_.9\TQL26YF<W@roYr&VCPnFIRAU%+,!rXpj
	;m@C*+/Yr!7`rGUDk</#A-g)(2a?Y_\:Oi]NV%'eHm7:WdtD;2(tVPSGUiQ9g=[iE=ZM\ikuF%/
	>tS&&l9t20jR"i$\"1`'$H?h(9q`2`@NJ<V)ulD?OI/m"I_gZ3COt2N;rIF3C":f&kUgZtCc.)`
	-c/g5AY8ec,V^YD<t&-sG`>M3oc8+`PXin!.Y6/!>WJPEsfgk&GFX<Di,/R_RdJ]%)DshE0-/Lm
	k*bD0i.0oT02d,^P/Sc_f[e?VA?0k+*s7[9k`P\72Nc)RS)l5EY[4e`Ep2QhH>nTb9o#Tom31Fu
	WG=lGp+KReVRPp.*lGQL+E+p>+;K$>K@OL/5`.2cJ;?8SY,<>7D?T/kKo:,@p45$PPKF@.))qi0
	sMTQC_MEcg&qUKAF9@??Z,d0:^P-6;[O$Eg#XuH22n:`kNP%T+'Oj\h:&AYD7GM_`ob3AkT*FA]
	(KJN``b#)1.HlYC=6!J>Z^-PUk<b(RIn]T,3koT^"jcBY&--rr@@./,&TkpkRjiJ7OsN?!hhkad
	nouq'9dKc*L__7;>dO>@f2X*i=:1[HV%B(&=IiGe`rNn3=_'JNj]g9b%Qa[DCg+b:AMJS#1Zt19
	#?VrRK(6`WlU+CVZ^7@WMr`(fb@<SNA.oT)D?`%tMOISL"$A)K!79n;l4+p1Nl5`gmLV)W-H]\\
	CcfR-\\Vj1&lI6=\m#1Ecmm5Q`t_4aVODhJ%e]aqX&$?X9keA&QK0]KS4eWEiiaDF*c$_>XN8h2
	gM8)WH+W/+)qB;J#SZ[dONf(%HfW%c23U:T[YYCG<mo]h$jX:Zm(R,[d;9r7flQQ/d%ij_rMbp^
	,kLIr'&W0?!^JNUO&OfL7Ej4:k/k8JfV``<*<i`'D+Xc4g;<k-W0<?;H0+0[\K@I[aWX<_a#4Z[
	?;]Lm?Poh`\XTp7h=fA,@R"AalS!i*B+CeKfrc<j>FDP$;WFPA;fMXH#9VojDehjd;s8@:p!@?(
	RPA&XhSn;i-3%.t.0HrW/_i>A6\!#PP[S[)jp=at7Mc8%3MsQAK2R&i8;I4_lUCUVc-@Reo5)JZ
	`ia@^?>,>>(=Q+8^&,cCP^E%gRc*]I9-9a/Js2$](r<N4YN$Kk(>W$/BP+*A@Xt8X\2S4eulZCM
	fs0B6dbk#IB[)07ENI`IHW4i^U!.\3:T$G5>FLViM8NqR+10fkZM6cj#[U`5,E(T'Ul>ACtQoFm
	;D2bp9rbkZ2\\SCIseH?.!>2U3u8`8;'4cN`Y-?3U+4ih$_H<g'DErq]-QDPFrVk)On<i.@V3Oj
	g4O'k6,\/4Fg+0;?n@aPb$c;PY"GoOSmm^&:aSJ([3.)Rk[?B>4Z93o"fV!,DItXf%??&L3[=BU
	,'1%SEIcT"Sq2XO<Uf@k's>f>$4BqCYoKF`<T,;glCI%un:VBU2sMrr@Y-_5-?MV:C:fULA(\DW
	?QuCIARAi+q[5PpK'Mp5jH38cC:9r*;;4c?Ub>Ru7+U_>'\h5I.bSIOKS#e.'[bJ`9BUmHreTqS
	dBAf&R?<2b*fIn1X3eoP#e#X=3*EP)K>?LL7&Dg9R]Be?+Ce]O\DJ+6_"2iJ3Ec56?;OIQO#g\s
	h49;t2trBA+SIY7u"C)3BL'Pu>0m!,B&[@H!$eW@@,-(B3I_FlDjHTp4)lFDb.VdQ;C#]CmH<YJ
	lQSQG+]s[2i!_@okI7M<s>$'pqQ22;FQ\a^l`VNX,^lRcho$b4nY7V$*n>?MhIO,CHsFUQ!':>*
	=9]]reTka"@0/ppX5NU%l+T=_)fbUZ(#un0!h"EEki-2K\R$)kUE:>NZ]o;HS<5<d`;$WU'<rjO
	G_YNI3RRf.2>.TjRLjN(<b,IaI$?ch8>@p\t4n4^Ms,Nl!I<5Kse*9:H$BJ)1&?ce,St?L[spa.
	#j;lCKH=^MQ&,Q9.VgXCVs0OjLEr4pf"*5Qe"OdhMDTg9q&[VaB!]h4Vl1W]94bV/+b+8*OrIFA
	#sMkSe>uBBFW&_U^5.I)asr,=%0sj-,!L?^]E6W_M!/mGI@s8uDsDJu9WPZ10dN'cd?h^CP>(-G
	BT7Cl5sYL"j:ZqfhXE`pkhYBmfp\6gL@s!JeN&"(q`8,Z[/++Y2WY^[F%0`;]fnlL9;keGfNc^E
	_`6paQ`[al<=#"'dNEB5KEk'_^<.;W"0Oqi2G-fi;<q^E_`_SNgm]q*3+#)oZ"#Sj-ki;c<3s3a
	qNbZNoN)N7j@Y!XS_ij!d;j)]3_\rrCf7Z)K_]8^F:fk^9*(!!K[<Qk,!O0I#CcKN[^)@Uag,=4
	D4O<hu)V^I.,XBfjmo2#U4a*"BEu>52%a7fCl7,<o5!a/3+U)=X.GofS,[$f4?Q*MUi$1If3<AO
	ueAU:Qc:NGAhgJF*A&l&SHUS&EYVq/+59<_V$cLYoMsr1)BX?i(==Ij&.C&)kIH>I4$Mi5bbY0*
	L>7J9E%29c\JBpmKR=4#'V<jDXr1qu0?7rnpgZrrBd0Y?q\85FIK)4^V"TQ/@3Yi07)3ALg,fW0
	qb$,+KBNn(f8Ph)CD7Z/nm%rr?>^]qBcIqZ?[Hds`bFdJ?#7Z#:Z>Q_[h[X@m=Ob"U1t&M"@W^"
	%r-[h[AJRtWe23%M?.fA`E^S)M-":D<Mt4$ff:UM5qLXg:#R0oZPE/-3b1N8W^.GXn2p4jJfS\a
	TuV_-?SmWUS3KrH3r]ps"+L;I@XXm6$E(iE,pkpK%'KnMA%r'q=1\KnOd'VZraE9<,V26:VEn.>
	VUSl&eh*,(s43[Mk^mXF:&W@jL'Ho2G5GrX*<87t8Beiu!4^k][4&N<W6<XX$EuT)0T\8(9r)TD
	$q;!-Z%\/M:&KpLZ40&!]!_K3g"T^(TZ0!"pn@p.l*3Qh'D7pDiVXK8(Tj,7s.<\W+;/eu'<3%]
	!7]kM1RV9OHL18T/V<P?tj!j?`5k#paH%T6b9]mQ$D"TlJ^d"tl8?]O*Hc5)8?#/pS2pRLm(#<$
	J-qSPgc!?\[c[65[f7!#`n\:3+i0nQE/[a_Pb"ijXX5pJ&$1I=>r)W.2ms^T.5CS]*[&phTSil?
	Df(`G5iS4K/`\b<1^u=6`RRq<h;>P!6(;-$F\1rr<3([539T^*B.ucroWp4lkQ$!7*(d4(`ua5s
	L'6c&qX7A2#8?5rf'G)=h/%Z-UDh!83$Or'H>A!(>0;5M<dM0*m$\rrBEUKlqDf[CpbL:@Sg]dZ
	=q"O-3>,rrB\VAcUkh5)+S@rms3/`c$PP(@g"pSI=I1NT'm;$>DDJC9u8>]Is]aR0"k>5A4ad>"
	MHigW&/*EBkR*n\mB3NW(g6M5RoS2PK*5&GV;]]tCl,1a%oc5r7cp8L).Z._C`"N+390"6hH?I`
	u+Kn=PTFNFqeBkJU^>>$9.Wae`a9gGQ[mO5Q*N@-p,HBERH`!9!H6)7EinZdZ<V7o4aDh.d-=3u
	6e6CU&-\;IFlnnHO!3r(#Aq0:YV58?7dN!']<)?d)ZkrO-KIa/n1]A'LUNBA&bH`dn$G!&a^>:I
	s00XK-<q&:.DE1M/f+_oM?t.Qp48Oct3RG>u=4X$nSCSr2:Jd!\IR>/a]F6[-qJQEdFGfL'Ls(8
	EjNc/ktD8D03E'C'Ri`\C[d-LB-EUscheHf6UtIr*oZ%'X2-KU2oa#<[45C:&7ddl++.RG"."b8
	WCs)>#f.Ap*;sW9]JN!0Ten*1f5g#JhMO:nQE&ib-=#M1-8l4;"=AC/u)g3OG5Hoa%\Q-1fs_[E
	'_I%Rk^=/58/:C8Y*X\@N?U,iX*!Ljs#dgI't$MZ+Oa7u8LX6+Yd:&795BI@ZT65]I@jap84h4Z
	ZY<CZ)2+GV+=PAP3aqb9s3eo^B[^fIt.V'`FFWc\6]<l=u["+b-rc>.p_Y$s.0[a_4%_[OnP>hg
	6rFDSYl,Mj3NWWER>I0[Yk-:%^\Ge,KDYrrCd1i!d2pLV=dDG>`[3qGL&5K;ug';Ij:]1!E!Oj8
	kFVnb8%IH7ok_X_1L6S4\M_Q.-i%oM=g,q[7/2!dm:Tj6n&H_0b2mLme]U.qq]!A<IL8GF/*dHt
	+CO$Z\m[_i2S3A]YCA]J^kbHdgd3rr?ROfcT3\_I)#``4e(u/r+.LiTo,R1kOjA67JIaf*_'GMF
	e[^HM"8W@VJi8TagW/$58+p3G`7*efV03`RXp^-2=t=M:V7cmT?XcgK[/VeW%_i,%:\N/#+N=;t
	lXkMUr5nV<iViD2b_:HCiaBdbO8>.=T=O3W5d=B!2EVj/kX0?]:Ed>Y&b8j[Y3d8L#"&<etSmTT
	"V%G*U&Q-FrAM@7%?3(V%_i:n;?:RJZ4<X'^S\!4O93LFp4]$iA1-6+7.%C.D:36Er.$O0tZ;Pl
	M:!c%1pjlud7Rqa@jfr^S`AN41$X+/1t+4?;Dn$@Fq^oWK2.NI5$k95AL5]!=XG'0id_\/8Mi!n
	bTpRdfT717N5`8$<'F;Nn^V<;urMMZ1\g0_kMD)"BhA<]rfMd@llOI4ACN-C-$!,0:ca$<Su)W?
	WOEFN&I^Yn3[Te98CAMPDYX3-79Din(uLg@P#tphcm2Gfmom978/P-FV91RblbFQIs8rAKf2*Mn
	g9dI)CXYCT<qA-6@)h>P6M.WCmn2/"]IV526%$qua%u0`@TU%H24;>:klCV<R!rlJ<sj<CcX$YS
	g";L)c*AX%c?jV]D2i;N$Ml(3p_`g%uU^qb(WaB"?liRqjYqB^n6u8U/3_^:,J6Pg2(iQ&.!/A*
	.0=S;t6//(cbVZT7P8Ir(<QUZELhp3-D?IOaP>57bD'pW(/EXGa\meLeMX![!Q#Gfc+V\-)oDn2
	o6rYo#Mre:Lco3#ru=7EIK^oj4Ej#hiD[`u!V=1jr7+f;4aTA#mcj8E\KfQ*S29XCNuM3fpj6SC
	a;OA,='Df9aSIG\-4^,gVa)*WF2g[<d()=nlPRpRW2j*6C=P0hHk2cs/;'I&KZBE[>)o)-$EgDY
	`p;MS_A'NF#*X0_h5@9fkc>A,ZeXq`8ujp3kA:FWZV8A^Y2@/hEg+7(eE880^\.rrB*0N#!F^CP
	*^4STc/fcJ0Ehd8En5cW[75O8DNJc[QhF6)si%\,/pmW\j6LlBYL0hsp(ZSmo`&F.\_ZmH4U`EX
	t.4a,@jeUn^q)]hVR^X\,@R-_p;s$hh+/P^Y64?hjBRD\hSD+--?Cb=^4Ae8A=d#kh%.bk$gq^m
	o;f5f)hiiNX)2d?Gq-C<`g,WB.;Q>$2ZVC6.%Pi`F'ZgFL1U4n/3$(K'\@UmaYFH>fI8TRq%/r/
	AIP#<WKC<+5;2WSuYn5C68ZUJc6p3:)Z\p4`"6m:YB"NAo]Kph-_<MgR6uXW=j-blYpu)\>\=Cu
	n[<,9frWOhi9(<=.V19A.jTT5psP&up$%G?p5Ep-JY<r[,V]6/6j#poA7IiS?mb`QVM&ZUO"]>Y
	Kl-boB-I;6$rBA<Ls#:#`EWSM+JC;D@llMPI4R6hCk%,G#2bR20J,8hr/RX9cWFG6D!+Rni2>g.
	b_BT)Sd*^L?Se57N!_-]3?^?:ad]@nU`UBm;55XLE>3=bp3*loE?N+QFjA*%lSm`6n9<p$8I'oC
	?P0@^8*k)RHVtIk03U0/Rb?rm*g9VoPoH:5?kkg4l#nfubS#o3/dl[d66?Ui=1kc9!!Jrm7d^Zu
	V*6-1uM[hduYj&+'5K*B=",9dSWpM"D53C\Cp+O8f1drr@bcFl9gmnZDMOB4VM6nY.s:EGU),R2
	ZLlp`p@Fi9)u6Q=cL[@luq"geGCbCHe=j47c.P(@+o;@D2B:^@to^B.*5mi0WgUqa&qLRa6i'4f
	>C4kqj1P22/tG26*lYAWq4hDK5`m@t:*TI]O#<._p+(V'iCQGLt#ULF,(dRcF2n<Jo6$.r"1];l
	BSm^Llqjh[hnsi!i1AnE]@_H>\RLB6NT^$@,Oi-=)(5"Q4JD="[XCiFl&g$F@'ZD/ZaB1G$-O?G
	.f:L!kiSDN+G@j0scN*uFhln]$E]>FW<):suL`mB+2,b`S-D>`o*5\Z_:6<K.tu.[,$IVU)9^e!
	4/q8oRjK4!+P%3VX-^:4*W"oc7PZ()IlopMu'B[&@TGSk2a2;ILL[6\<Om+#*=0fA9tVq*m87SU
	3G5Su^uOBRD-G!LmJkk<ho1[!t=+;qF6E0A/G,3Z#_K^*ihO"s%V;bA1a3.a<#\`1VmqR&M3IbQ
	?rfCn+m7PFQ6pHB]0Y$1R2'ZEi\T="2:me#r4c^Pc;K[s_E$Hrg30^*n@JpoAPtO+T$*EG'8BP=
	H(8WV2fW0]h8,TB2@io]sLP1'+Q%->eCT@?qiS]'lu7?RBdPZE.pS'(HeJ;u>15RN_/*m&TYpj3
	P[058JWWRX6&5h4laGIUa01&Yj5G,)SQ.6?A<0eDLs\:D'((YS_"?0@dem4PP4H6Rp+9nI!!=U0
	itE>n4L,YJ;e5GbauKnDB/rNt"a1iL=PgVO%'=,#sV3E+In2Dj1aLl!,&VIN"MV3YS'[q6\bVa.
	\L.i[SOoY6\G`a'C_H0CAc>n9;l:(c8E#_r3fjh!8lg4kna"Gp?ZI3hTApYj6qjd]pkJG^La8on
	hDr\)M=ti@u1Ze,$^qCZ"V;IQ@DL)ZKfUDhXeo2'3@IQC^/,k)!k^4cR[[1GYb@FtA9"OuEi&S/
	e+i"`8e7l!\QHTi5-9PA0adG%g$^15`TS4Xnk.U`u)9rrBqmNjHFtZ$^*YAq9DXBHkl(B@URNhU
	Fa<_4"1rR(fT#GBX8'>]L/keSi]]R_QC_<]Ll#lJ/bKbAOmE^\ZIW[mPdGLI8>-=1YlTePZNSX,
	%rS74c'"G#T`P"QokEn8iPiI#?+FU%`M);+b`pYGq&1N]maDgJ\!^oY2;Kph'AP$cf7!cMFPWnl
	6=Y<S76&^`\Z&p/H%!B]T_VRch&bok2<F_;]$q.dA):j0,1IV1.-jZ`Vj!O,*H*Q\V\sa,@;k?I
	fhk4k'm1R0HH9Nk+Q`r[RNF>fZ+eS16Te>PUIDoOjkgA\VQGV$2.bD`-;B8"G#.rKhZODt[Z1YC
	QOjV-J7`:t2mk[Fm\-V5&-i0.pKY3F0d,NjpFJn_'HmA*Mud8P(4@Dc_%+p^FI(YSAkBU>jq=^S
	8%sUI+Glm7$MW9@S>"iN4b59cE:e`7erpEsOA84>S$fh;@Xlp]m8]Wa[_gA><J3>g'h4hR]:94?
	dn?N2TWLcaBD#qB",_3<%$Gf>:mLSiP<nkgk5$le4M@N#Hi6M*B6'M27,*7ZlSGE,[K8:Gq+n3O
	CN.RSe_3,:)a8?caPJbAs&=4?Z88puImQD*M'@5I6ut:P^&+p`]1:8Cb@!J#@$bhN8hmSS`AQIE
	[:'JQ9T/Em*&T7<[fqr%2/[)Kb,1N4&6,**IFe'h\jiVc!sa/Nibj8+luY?fKCch@B'uYDVs&]a
	Ecf;2/0t\dAk%+kfK'4D0QBZi!fC<EM:;;Fs$b:Ko!Zf##h)CIaYuI9O;X(%S9OT-8^#6N.\o^Z
	'^-i2HQ&iQL*i4e1,`E401HLb_F93?t[;j^2<2ppq;D<S!=7[BK0c;a8-#`C?;k)qt&a$Ql`&Qg
	pP;p^-H0_r8O;]p7]US\,ls^61_0ULgoo;0_8;@,\QggR]m6'#;g0?<F)+gZ?0(ZLQ>^_ZrXjAF
	>WC[eh`Q-C;]Tg#'dK!$AsfcO!eMP#rO[IZ\HU7HS!7/B)TS1,A?qPU8rZ3r3Hp_<)Fc)![-M]d
	[[p:\s9U1G>kk_*M%DWuZ]J5O3CQ&,8Qm!,:gf_!ue"Ih(ediRB%^.IElBq*D;22dHhWp>(Z9FQ
	1$4gZ6bap!kA5lMg[)q&_0Ok;&n,2]'[%e$](#ca\I9Dh-mAJ,!LpOa/cBHL:@EpJRRkm.3aT,=
	6Z*M?(tDPMX"m293AI&a^?r=tfLCT5g-(5I9kYc+D*_rrC7'HNB5;Ycf&>`+J&\QkZq@_bR_qE8
	,V%NG/o[):.8R'pKZDT:6pfF@i"m2B]I@+=[A/poI[Y8@";e83@rYRmr53B)T@>)0+U'g5j85iE
	/IK9U`AqOauuH(s*ji='rhXN'*<"N2=)]>Pf-4C=5:!r!`)]G.018F%*Bi:":cs%l,"H5`5Gblu
	c.@\of#ZY:@4E:2]qbBYJ#([Irq$RqFn7eFD9t6AA'DRDMH4JWe6tJ,gH4ef0j&-[sc6))RtFrr
	BD1^#BJ:;*KVJ'O#XEa;FO/KH/-!fk+kArLA2c\O$ds1nNkmS_<`7rr<&l>u1G+WFt/ZB`A)%O@
	>qA\K.FUT?\)h^Fp\c-q`OLf)hn:,FbRM[eD>#1]&>CBXIODn^Bqs-D\V&3Kd*$;IgYU\!.<B!:
	-nT)]jO]I;45Z%P)TK]/uXj^*1pH?]6':2%;9_!I(2]LJF#emCID>_;LS4=uYP=#D:9GZ#11MW]
	D3"puC@0r"IQ;(W)4;l96Tc5DhR'VeK1/QY@B;*RZi0=Q<a9kB8rk*0X[5`7:Bg@Zd9.;S*V9?2
	^(=B7Clc=s&e&"6,pal?\JGG7F.Xf@R86m:A`qX)SZ9#T4K#4&9HF<NB:^KTah0(qif=5OECZrn
	mEppck_CO>LmZhB0"9p?k6(EkpYTrp4,IIXlXFH8N=2q0Ec)=^:lep^?S\=oG*Z0km3t8Z$.M-[
	WO.;Joe[E8.:YO8"ZR1Y&!sYu7<m%V#XPSWDHb)#P!8^Pk>dh0_/M`@ZHqqKhDq6PB!*W!AROrn
	9-."5JrY?6j/3c_%2be^]`":D%8(.K,dN0i):1c)5fa_]"EF2^sgr+UoEllAhY^F^clV:,QI/N9
	5=XrM9Car\J8\*kiA&hCm?d7/'QGmk#9[D/PO==HCi"4]Ra@Y7dWO3B4@=40,-kEQ(2#dOeRh!D
	Jr_P!GD::4!`hUhJgQ+J8#fCVm[&0UDII9TA8>O75$njo5=nUL&_#hsN[L2Z;0R2CkS7BB[WNp;
	POaFH>,$`Ud8(@[s:-6.GHa>Xf/RL+6>c40.iG1UB98TpJbnpAE=C/Z,$7:B&N0g!8MYGe67g=]
	c+.;FqHi5?*golF#\_E:4*hSI'_2rr<N'*ju:dZ$9q`O4ms%?c80%@e'-;`#jVX'um8N*ti:Dg+
	L!TkN7Os[6@$rOkVFVa/Z_Botl"ZQc0Jdg*ak#')2uAeS_RmY.PdVY.%l+NiJ8d(MHr1.4&ud@/
	J:T5K?RQK>HFdhatT5gJZE]9qsL.Q/Z]mh4$Ps`1EYK*E;2`=:s.%ae0/(S+[6<Hs72@i^^r%*I
	LViMCB1\a2AmLB%GO&NK@Cj."Poo"(bX0!-uN`DYX53p+>dsN\jOcQ59HNnP=mWrZ'T1/K7^;DW
	6QBBneT?4.++E<\_aJpRB`a,1=5:/RM0$/?^#QpVjb_[[K49[Ec5h74;1GZ,`"_V\gXA$(qg'^r
	LiohLICE;6E:FY7KOUPE6urKr$ft5l!q0E'G9!a5WkF_UQNMBVte0bO8u`fj+=liHBo.MuFscZ-
	&q4o?HC=mBo^\T;fX(C\d-:_FlZ/BuX?BbqGBdn^-6Pk)o>%L8&f.n(C6FTq&ooFPNO-rrC)r+,
	,2A:7nhN'A]_fqgJXD<Rm>fffOW:r]5F`B2DZubo8I1e=<NoK>9U,fbh&P\e7R&)+)a6WV!?HN*
	/?JUg'Akne]N6'J+7uZ2cj]q>G"r^1>BNIF_nU3te^(CA<(IBO%@h38-*LlW[D=j$u6Yn(dS*\n
	Db$"\2BY7=!IpkZsq$=1M#"'gLLZr+T9/b>@IIndC.[fr@&)\MSM@T9q)-!,5.X%crYFMuGRY'L
	jc1BXh/2SE$_5JD^V3'S'FuV'1cKXT0t%(h/"&!%8Eu!!Q2P5G\?&*7+_n$33Zu>QAJgX2Q2%qT
	o836OkLE,;]C4J.1sA"NW1(,B4UUSoI8f]T3s*l2+%d?O!o$-VYA9X6MLPgg8`&b?ER$o?)(N8,
	,C1Jke;/U<><<R>`Lj^0%KNmk3Ifc^)iIg3Hr^8Oo4F<gQAMI_CeCdIkaK?dW_5I6QpHSMKIF\;
	KBDaO--3g$Qgbo]J*j<2VcUFQT\OV2qFK<Y_U6[,'`le+,="0j,G*'S'K,'S&l0`[QG+"9/A'5S
	:7KXYBm\*@Ls)H)5M<'H_WR().0R!KR+,!AVh8!866D>V%$`BXh/_PE(mq.gM:DC+^8<bGB42:G
	/3V3(+#O!*YZ.@Hmh,L'.h`1I-Ye@N5^X26_B)BqZ*Zq"p_hWWA'o0&qIF-kTZ[-0uu[F7T;FE;
	5P/pfWer3Jn5")qa_\aMi'DG%2=u8f5k_AD.R`j;Pth[2S))cdJMOI/3YLrlR.V['t]?V:28m_o
	@!^F/N<h5BekA/T3'XKjk&lcIV.]'3ikbm%1gCCRG$tf/u.b)tn@CVVCurF24@j[O"i:.38Q.4]
	5fPA4,]S2<q(HX%cHVS67e/IQi-RpoS(q2SJ.!F2XB-&>N!`jLRs1Ai'U8qL_Bsi<OIU[eDtZrJ
	ggW?laI1IN[,;A+;3DP=G&lUl0;2U>Dd%NCC\+q1s<V&3qL!)>[_B9lek(Uq'pEEJISDTrKT@:b
	Y&5aYl@@^MKP;-cWK0YNe;0pfjVT:JSNF\A%J"\,q"k$-PKCrr<rNPN@jn8N6il4\@]!DHZr#;M
	S5!L#Hs/^Cn6f]\6DAiluP]4'\1qeX<+2DY]#QJ:HK"f4:Q]lQpU/g=VH`nL)89g)%[Cf(XCF,P
	ZnlkA1pmUq:0`pJHB=qVZ^h<eWE`2.u-FloFqWgjBKprZM"'j0nJOQEM%;SK-\5dpZ[Q)J9:ja?
	\g,W&)ro4R>LdBXo:kZm3bp4tQZ=5A6hh6i:3#]WetKn?.cma%)26"3(l?/dV-4L4A"b4'/+BQa
	2=VZPcE(T7;@,4oYLp?hdQl$<P/LeY.W7SgHk9SRc*!f%6uWHP-jV_ps;:)Y7r+IAEsQ7aR-Wm2
	A4/m0d(lX/Pe?)%bS,`V[8tq,q?8R:69K7R">#9)1MNeI&j?n-a?FIG\&qrr=kA/+D[O&!^)<,d
	`ccG)Q-,o7*ZZk!/Vi?gQ]uDrBin-0R7!9lE:TbLGR3IVXiMkC4LU,"_e7ELZj"^;C=[Q1@)+n^
	EKj5%jlqJp`$pOo-3oX8`/*k-95pG[&,sQL_B'"Eq8F+di*.T.Q+t;uAN'M5AN;XjI]FSWDA\Y9
	;>u.&mj[VBVO@k-ntb/B6AB)Dh:oTaqe2G5"cP9-S81]d+T$lc8$k=??H^<j*FT(B0k"%"9#YQt
	arP]tIIe"n<O&TApIKl/Gtm1bGb&Vn?>5*;ulW3j7Pa5OYWEW3qq'OJr-thu;G]nE68$o3A#/qf
	];QhN.KenNM-r!.oWHEfS0)lf#Ra3/oP]mdu,Ta6s;X[f6>+NSo,<*Q<F;'BQAg@qi'PQ`!@MIE
	-oUfoh8<)NT;Vld^Hbk'ORroXhkg^Ct`3M-=.>>kf,R$Qo9n2AX].*m/`W,[.iO10=Y\4,"Z=<0
	.4D[XU/!9g.*'e89>T$Z"KILp$+4@p,M8[ua0$W5C+M_hM%p+H?m5/9*o['EE<L!e;)bdXXN+rM
	0?8V;0Jn>/FS)2\OuQF7TpQ(ZCmVHj]diNAH8h9.ch1em?$7o%j,ojK0s0W7grgiFhpai/=.@p'
	ok%e:P^E\K<Smrr?+Be=W/CR-e6r_#-2D/:FB=>'&8%h29e?^&76.*&tT$e8XiPY:$&MgY!X;iV
	b/$%n*e0/`oV;Am#Z7aA1o:`JHJHpklfBXK!icgXE(YD1n\WC([97Bkul*Dso7'.YTn@$Gds`ZN
	jW`4A=r@&^T%:M3CDN(=>bo8E154(Op7IeMbc"R@eI%<jqa$W:Qm/<ALn$3TOi=St<>]h5!`O9p
	n0RcBYKKDRT'd>@qa6NaF'%iu`h9^KT'gYqi5QO$pKKjg-=BG/c^5f!q"5G."$9#+oq8^><u>#P
	tDiobCOS-<mpd\@;OO"^#n-c9E4K89Sg^[a,Ts(E(=Xl>L^FA'?V(+n9;?gP<-1WMJ8&[#EBu-\
	N)UBM$pS^="qO0Je9MB,/jk6JB9U!8q5R%X/iI-GJsD+tnM]1,oDa?I@@hod2'd!$ot<L]7@HDu
	Te=rr@QhQ2^jIir9"oJ)H@e!/5pmSE,`i3\g@.!/)shr^rs>@K->jg]%8h^YfWc^[nZ,#Q>"$n?
	5#4p&>#G_kM_^!+JiUnl7>WL]7@HDuTe=rr@QhQ2^iTJ)EQ\7K3@AJ+91mQfA:-I_H1cr^s*U0`
	M.EmJd1E?gn6@?iGL-r!33,htU9f)bL&0P/F!m4pk*b8u:o/rrDZXrrCtan-@'Bq:FI&!!GOF?@
	6Y:r0BJVrr<>$rrD,[?IKGb!']<>"oeQ&I$O^3SUKDb7h:BI)a!t,d*M[4C]=CV<-q;'r;2!=(]
	49oYPd_Srr@X1Hp7>T#X@gfoJ>g*"g@q+,uaN)J,/g<!:VZ:!p$Qb!'_;!"9/?(HM@m.3'@+Bd#
	\.IU]1=WWV]@Jr;(p<(]4>_Sg45`0Dl(S#j(P/`^S2AMV8I$Z1)]LrrC0@C8MgHI6[W;rW&KO:J
	-QF!!3*"Jj95GIuHAe!0X1OkL]\F!WN/A<F48`rr>6TrWW<%!2!n]rrA[lrr<*"!.m$+&9!N$Zi
	:"5;o?S&5N*.Q!:Hjnf*VHW5+hfXrr<%JcP?H[58X;$rr<1f56ZFB<m1D:clIN>KQ7"l[oH&''E
	3DEr!WK)/s\-D<F>M3r"795c\qVpIO4c:%t=nXr^j$TE.@KDrrCtan-N(!^[q8Ni#hGZrrD!bpr
	A$e!#I`7RK!8l7/m8X<DU$>?hdFs!!<0#J7#Y%rrCBqrr@TL!5Tq5_>aKP,AbQn-c<6N6/a_/rO
	T"/E*[/#rr<0$!.\]3=P*&mMZ3[cJ)HZ[_Z'TM6N#\(cq28r%5@e^gPXBZ^jj[eJ)GhTWQt#/QV
	9esn6c1qCbu&&?]'4%rr<E/6-#o$,:EKkOsp%V&,G`Kr"&f-[1B>#?h=pPqucs![Nn$Rpn@]f6g
	fOjmTOQ.8>FpI5Ng8*n3?p%4bdTfpPAhLi4o9D#DTr@&,Dg("9/@AgOJc_*np_q!'Xuo!.k.Mp7
	h6uTD\m_rr<6&!;=F1LNH<3g$8(OXn](keF_9#k$$L&X`#GSI(59^fYPDgcUu3Z9I-:].T0'SQ2
	^gl,GKlCFD<10Zt1<$(4Ufir/L.Ypl`t?*Zr,I0>,W:fu.HEMDHN;Nf&]S/5?0dVR^BfQ6N,=6[
	!Y)XW02I<M%Crr^Y&D/CaTI%\"!KX398b)oOZo95gPL;B'<t6`1of*6=lt\)/IkT]f#.m\hZY1W
	kkYJle3)QbD3>/XQAqq9C;Hq,VIqj&*EX(2\)8CX75(G.4=IbWZH?f=WW7GfsHFoktT?OlhF#D,
	/o^BN$nf0Lm4(Y1(Do&-iSL7WXEO3jHS"I'i.mQI#*4l?ep/():LY(Pl>HC1!FqDsl<Nrjj0sr)
	VGI=lBZL;t.uHGFHeV!5l?i#*p>\_L96205e'1abtXRE8*\B:4Bqa$pAf1*K%/'DX6BNhVW>CR+
	^K'Z)`Dkh9is*5FPBUrq#CCf[o.Q^#D0`GVd>XG,#8FVa:iIUO?u'$bLNufZ_O"0f]15H#_UZr/
	Q&RV+RZ:E:%\hFILVW!0d<up09\I<Nf'\fU0'+m+Qcho3[A=JanG[^OMp36/eqDb=:&#Pf7otA8
	`VV(`!;ukY=T4q1]DBf??Os43_&Za4NsTX$t^5GQ.XKO2gPd!6Ie$JKFe&Qi@&L/#T!Kr/^jX!r
	i7N@EW$RfA6H,":p1b2ZEd)8FV\hrXg#tq(dtX2tB32$iU-HfD]peJ&)tL.Ik0^`.&$Prl#biq(
	@\T2tB32$iU.:C]=AqqnM'Grr<=s`t$u=r#A5AKP(5ajLRA@hoPftn1XP;b?t(sh>[HX;;k<26,
	2KUGVkIKi@2P;/tY<Dq'H%@JUbHW/UuqjGPi&j_S7(qrr=>U_1_O^!/aBur_007L&OYni(O!#QP
	'/]mf*9=2uXCrNk,/iP)%tsJ(UY`rr=BEkJI6!,ergpr^,_bIldJ!q2RWUq!$PRrX&T)_G]Fo!0
	\jQiI@"tp_*T,+Q^QA!'G_nraQImr]D6o&:>$RmSgXq!9D9_YeS:5r!@k7q/IM%^?>K'4>HBa+8
	I<+#@[)[4.lLGURMYhP5bNtQh_#U&cCt_J*%!R59>/rqnU8<iCfgB9V\'br0%'[^mFj%/gpJHh#
	@Au6fGe@ICsj`6iR.,Xk3RQ-;i$Ar^hUt9DjF/'E$&AJ*$jNT-!n)lbJ#F93m&<AK9?0jHn`<a>
	n6)boaLr!19P!^E.mgH12pT'%^LgR7B.Oq'Gd=nd\o#o1/4ujsffoa.`M51WP%G!:Z>errD-&3O
	$9?0>2jsEoMS;5BHi)0r)Yd!$;.?k]cM.pAY,G?LRmoP3D&Frr=Uap&7;>`;]foIcp]?Qc&h'*j
	a1PHiut<M\gm@QU`qMq.9<(nd\o#o1/4ujq",4HdBmq?N>ZGiJYJM9;Tmer`O[8r.f)ao1/4uju
	</Bj6upVScJcj_Ii9:!0ZU<@6^&bHN*sgEoMS;5BHi)0h-leo=p8I!WN.Qc0,*,-.0tkr`O[8r.
	C=Nr6bD6q1E?f++K'cIh2PZ*t;P+nm*6f:Z[r"^W8!`rb28Vr6F?]oq.5F[/79$^8msmf;;A]ha
	>lS[#H<baE<YK$#Jdd7ieY%USQW;8YtUL]g$1smi$,cl3ICQ4T>C2bg;(>"D=oeVO31)2@Z.^cf
	7\)YLIuPE.763K[iTP7*FP$6rTaZfG/`K`cG@kbS)fiehX0K(g]0:PdE<.VR!)eKCLgUW@CEFFQ
	_MXj]J^ckk831WO:5lXmbY<=Djg8&H;aG=:mlCeH)/6r'0\kL@0N<Uj-fKddB?_Xc8!1^ZMO*2^
	\9,DZNB1J.,6Y0"KoT&,;RD9k-N=2.od:f@Fre5l/'\C/&N[[A3MH9^qG[K1j[11q4&um-W495D
	"D6D8!`s,Y9aJDMo\m+JT?s%o>\;10;<'!d)f]d?"-FMuNd6Vp,$h`;\,5'h?-e!DbkZO6sRGgM
	,p(CQ\3]O$judG)l7e=mfn-gaeUr^F^\rhrXi-f^Q=Ao:0i\7JjT102@H)hV6KA^m[0jJ"c0$g9
	$p``MhP8/gHnW_E`1PT(tNtEbk1PF_XgQX$PH2hYq0[eU0M272\q$)o>4lH#7Kj5=YViGj`c7O+
	HY?W)Z@A&BAp0GnEXQ,`Id[:JaK/qj(aNR,OfH*Hte]<W.#(PV]DDVGW>E(8f8fh*%D+q3p41Lh
	K>(d<*e.Z]G+dM6CEWpH16#N<G?R'gaF:)5]ur*0nlYb;$\'&S<r#AYY^-N;,VCP?Nc$p/U>Z:d
	l8m?he79e$FLGl9YAhMSmWtO2L+pQi+SX`2OjFr'SFnpiH6.T1OO)hL#Y,@Jg_Ppcn9lHsbjoP2
	F0g]u[jo]!OPJ`HRm>JVW('q9\sN#MlT11+^:%lo3IqHuW2$oikeqB>NcaI'=H[X\ed<m[EA6\*
	B$P5@pJ@qb6dk@;4]8'Mf40j#GOXXQ1X1Q3Z<.Y`mU%(!,<\IWLWN_+E4NY>>/u8bMZGqp2RiF8
	C.VW\p?IJ*C:2IU@*[(>fMm%u7W8h>BFJ\$FKGOf"bfg4=2/ip>?1[q,`F)2TVm%2gNW=<t0HoB
	]1e?\sbW6s_&+hR0$%!8RSSAN.'9rrBA^)ob,!$@RU13aEQ?>'Gd4Q0^,NnIZ-.!$a,EH42JA!M
	iEi+oI#q4SRhONjUk#9b5*A'C'o0r/Ws;jsr-4Z_*S.TI5btd_7@qc*9!A"dRPXXS6FC%p-19/t
	9Sp;j6ud\Uj8=i0C3nANh:-28j^MUj8HlD:%%/V9(rM^!?ei4P'd'_I$<CYrL@]=hCNA:%e+ET$
	-XZjc(\"Pods5K.O`!nJKm><_X@J[!Hgh1$6U*VBb^TrF93@=&I0)I9JiT^*hTUO85D2KlYEm5?
	sQETqiKKemIK]Ejc"P&KaKdgPNX\B,T^:8Bdr-OqaOQor8Q/PAh"%!0F^i.3r>-A-o%Ii^RPd'Q
	>)'`oEX\rr?61O/\YXH4`Gc'o.T^U3F#1k>s/RKF(T]j=g7_E][m59(4/[d^(uo`o8\IN19le1\
	k*)a%kia+s=ftnZ)\RT]2&Y'm0n^[$>2mA`07iGR(IM[1d`9/Gr*\!4muba5=p%N?"LAS%5d3`H
	%I-F`fn(.NX>%b^YqoERWWm%ZI\7\Fqb6Gn99anY]:[@AW0K2M[u@HKU,I>B+YZBn+f3!m>LAJY
	Wq<AdI-V,Q^6Ro3E&E.CUYrNi^O%gepdg6f;mBQC\HQYCUe&LllH/(%EWUE8"<n*[SFMk47csN3
	Tm]85GPF_NUPk3*tN?.W0-%VlEqbq#["B8pW]XfDbj0,1:kB1]((rBA,Pk^[2?:cd"YSkO7Sn]m
	ZrNQ<fJfN\BC9`k<bYVP2t<)'U!$m^97OkU,$7jtSH_>]8@JLe`+&Ss_Uu[AQVs'5O=\mNQcf/>
	$!R\[U.k/p02Hkc_+"e1K04[])<pZ)Qqi!QZ?[=PCp[Qfqq,61OZ8nFONnT!>4i#rZs.(NJ.ckn
	LTj<)"N,pE!Fj`u42E#W^!P9VeDPAM8gG'==s!Ih/n^'u]WVd-=e/[]_!Zc,>'BUf0`'I)DHa&)
	QMhC!I2%E.&a\)(A!G*E-90[f6>@1I`Jnk'<fCc+)'dh(aq2d\=\p%uPIIm#UO@m<q*2H/&&][E
	%?@36(pOF.[c%GI<-ICQ_qIK1rZbRIqLi<_3/<Bl4MM8!#ZgSlb%oN]A/f=nW5uMYKp9[n$4sCT
	BV27nU@seo.p8ATr,3RWc*&A'0Z=8e]NG44^fR8s;j>8c@^:Uh>#pdd$NZW1*t'[qjon@C6b%RM
	YkU1V4_'XK>u*N47F2bIb0jK2T%IjgXW34+q6.%Nc#fIT+)Tmn1i??mSN:em$h/dcq(LKgSFLZ7
	1nMoIRPo#M`,Y2nK!VVR%T*UM4JcU"O(g8B=\PK7ZSrnXj,:g%GfJ>Kp'k_o_dUg_SanLuS$f<:
	^t!<QQ+B_NgK.oR8f3n`Hn2lb+Wl$QCTHCSfVM/g4G5hH+7Y<Hi?iV+4>_cQ;c&m\qNRCijW'>2
	;L-6$!b0jbK6;L0U]$L.<3p61i,H0K<>_j%bT9r)hMI%;?JK/t8TOXi[RgdClU$,d/!!60b9Q,k
	5'L9iG%6=(2lmQQeLn[EUm>88aVf[<lVWA5b(sCj+uqCuClq"4FH`Oep(+];J/rY+g%h<3Uh<B&
	Nkec9D5HH/l"g45.Qd;jmEunNP"OpVT.@`k%G3`hd1?gP^n?m2:;n'Y:F]Z,cBec"Te>X#1'WaJ
	h$l/oRH67B5+c/[R`W8FC@?o4#1S5`qBN,VF+&obEeK%6e:N;7D_VCIPgl9:.tY?s,iZ@.Z"\aN
	qO8!Ok+\SWcI*h*Gr,Os=,+<%^GX""0TL8p4[S`b7RQ[*K;29_!%R,.EjUr&\CuW)'?`,(5nnmT
	%q`&9IDq3@Bi3XX-]]&YFFL"=Y]G*lhZ24#(=?_05pdgV<+W<V!Tpm`mQURa/mBr15qoa'*,2T[
	Br\m-h=GDuTgH+F'@'16/B>+.I7^h2kSJJ_%#gh/^9OS*ORXMc-pJ$"loCG(q?s,_BSWNRMY_i#
	YAmUWB-5<j7D"*r=P`Z5@*-16(]_W99HfK:5u&`:<j-`4lcZ0@=7Z]M#6$Rq"&*2GqQ<c<=pe,\
	dC4H"&OT!KqC*>UdsnZr&GJ.d`_kWEHU/(qP7=bS<rH]9n_j!&Kh$aS+c&-qO"m3JG@@G6<bD<a
	rA6&J<MO5;2%cJB@=_Mkfe9Kf.+ab0Fo::Sq=/ch;7E,],[)0'/(5^]n]2L_WdJ1mD=5'6[G0kr
	S07QC4T)cPpS^hnYDOQ.r%WV3E]$!?e]2#AGD,P?)N2Eq$YkY$TmX&\(9dd0CW@I7WW.]h$5:<3
	hNDjD2q]N^-2kPsA^]:(DQiHrI?`,$i#0`ecNingBf^XpJ\=n/:;6ciD[:`B8*%Z)l@T;C6?#Z.
	B)Wr$VT\Dm_C&,3Bt-M^l^l?,Vao"$+Hkks-5,`@m.\8&C/n,3r*\HdeqZ(-43<B#nMC9<!<KjB
	tNq"3E]Gdl!pM\rEQ62tmn5W*-Go_-T<$($QN9pUX)fL("m-<heJSB]G7DL-hJPm:&2d`^05Zif
	rEEm%)9ok=YKWnbG90M1":u/^=Tg:EV;QrY:hhZj8`i0I.!7,BN<I6q+Z*0GqjeJJ!rNIi;]`W'
	nsA2V-U:GVr<HnfiPk1T]r1&\5f*nQSSQ72km(lj#,)f)T2Z%@a.u082COMTqHJRskS:Y?KJ+C7
	j2f9>8r[DY1%dI5G'ZcZ%2FW+];BQA"3PHK2,L<(Tu?84i*m'DO<Z;L%rQ56QEVM^Th?kD6cNj"
	41sNOA^O<Fsn&`&uqH$4\k`M@M/2V&2gFHR+^\9dFM%=T,#-6fNTIT,.&@L`R29[.+raomJIDnf
	7g6\:WH!-^@AD*6F$R(s*f7)93qd3_<(!01U#m4$0$nj)<Z^j5F=<nT.4j#*EO>V;YVd4\*Dpa#
	'17+M#F1DU0JZXK($'c".eUr2i-Vnf*jsEShBnD_D^t42mD.:)tk%2B)RQVH[<k?ea:o`"C1<,Y
	K@bg&skkPV=&HJXWOre<`&KT#,QWL>;e/[RZ@*EN8pqe%QfH)b[lWnXb:qWj-@6mr.n;@@<mU?'
	K`X^0>[ZP"/,-KOUb>p1*6'@#t$1nLsen\blnVTQkNOL>,pn7r:%_eKhHNY%'EqnddHC1.Rp9")
	_P+B/I;TGr`(Wj;cn+o3W..Gk"kQmtZB5[>tCRn5ruMHpO)k]@:c,8ZnX-m&24^.03C[AcNsj+N
	n/_$J%&/3C-<C4O#6`XSnt[Bs/+^rZBPe(@1[#*mf:;i[lK]SSqAREou+OYdZACU.'&AAlb'`:7
	r#+rBsPXRrosU?:@Ied@TOu-2_/Upri/ef)F,i9bL_UG1!4mJp*RcBN95_1,'.,Z8/XrkEDF-CC
	8F1k@`CD`MkAYhi*!upf$/Uj;2,Gd@o)<Jhn*81Uu)5jF@=5afc?oQ/M2\;oI-_CJMY,He8bq0Z
	tU'i9Ig!md4k?oO.\!_`%EL,Q:+^5PskUr[t]Fe_I5)HnWP<cVOLWcTgVC?ZQ/H,GssK_p8hj5)
	SVY%r$%JEEo_nOsb:Q^gJ-<*#s/;l/;.1/cdhaLFRZ=GhIggNQiGL18d3of1W<A7mQI1oTA0q]2
	PpKjH?O]Q'u#olq*HVQ)Tmd.5E:s[#\$?::PBq^bV%(#fn7;db@`$P?)<ZX8!?'f/,S8%Vg/aC>
	KfA6QDPBrEpX8_q/QaNp:mgg:LjQP+&Qjb>ECfI=2%p#LrA%%Qod^f/4r'rLZk=`H:Ho&b4oT-1
	P'SHcqCU_9lN_UVj+gC9.Lrepqi5U@R5lI6$s%^I?=jK+EltVhqc.pch9td@Zrk>WIVW8_(]7;#
	FD<YGrQ2KD+m+a2=1#9(=GSn<`C$Id\)5A%mU+hJNhiH8m;/Q90i*\@1[!I$/odqnL4R#8:S9G,
	L.$l$)%Rrr=k??O;2<rr<CR6O\H_^V94!_[i2!6Htoarr@L2_sua#3kl*c'VDoN2<=c;7q:oLEC
	O5:/pTE@2?$Z=XY][GpfFS(>M89?2:M#4/f[@jZiWa`7Qg`:\Nc@)ZcTN\C!(Od9@D^cl:3kM9r
	/c-\*O#`WTLj'faQ4XPk@aWcU>(%meYloXcr39LBHa':U$t#;4W!2;cdeP[<d(B3gF8eO$$pNHs
	=-ZaY'(A(uKO%/@VDsd=9IiVpI)0PfHRGZhpNt!!N+1mBaoMGgKfF^YjTGmH?7Y7;6Z[&4Wol)M
	CZ.?mm#qY6%UCPE_Wm5,L#n32f8K+rS3=8n^nl3c=R;eu^\G.PTMjPJF11"P:g3g7sX]J.%lth0
	@0pBN<8$@lh[eE,iCu:G3h3f]T[JX_O8n6aW=c^Yp>i[OHk[YhZeMNiGlIWO9f@'B_F0,P)TNJV
	U!4>c1W^LYN/;=*RsSIXaCDAEjNr;T>C1Hl`JGIHm,O16@Kj#B7ceOl!%"cBio0?8`q)5:IJp-E
	`)oRF>BsMhq*WS_]()d^!W-WSFs!mh@K`^lF[2UZLCfJ)R!.j3+W[[i/n5Fmg(0RQe8Feu*6@bI
	+^h&@Jc.;H"bR-&CV94_qM7;+$m5CTaQuGWBft?H3Z<%tlm1mtCZMCR4u#"nh3ID[?,miG\WYiZ
	"qH6W]Sie];5GZETKV3S!i0nZX!P.qhrEPiL&Sf'>bG3E*MIjk.])rYU#T9h'%*%u4>Y[R9'X*]
	<rtKT=nnF(B)*j^d-\\8pjj\8C72kurF+9loplaieS21ZYMWF[th*r^SoArm-$Jd<ngLHRl:Q\+
	`'?dQSk7Dcc^sZU#j\eh;"fLY_*<NWQRuTj/t3l>]fRn8X_kUQ(Lb0e-,a=,s9JC4=K9Z[]n8$i
	Fr4mGEc-9kq^KdC!gXrr2u;(7(D6[+(h:IKZ!h:UJn.TpPLi^EE[r!gS.%3R_^p=f&"1QH4/]aq
	@HRpH!fXMr=&[]Ku(7`Hnr\_Q0ktqG+HW(".Im28%<9!5scjI)><p,HmHER9W:n-Q?hP4_V^&@\
	q7\GNOgc:!QK(hb,2Ie:%u,;=KWtHrZqFHoKW!q>=gn]1;Aeb@N9:NBZpee`3)[JF3[fIR%0+i"
	!:<$Df1G8^/kj2tCR#NCZOo\%5)Vrr=*()#1GW+0t'b]JZJKO/_C[/#1@gpj'"G]4tBti\PXe^E
	<U4EIr.Qj#kos)9*D]g[D?2FOZ8G9gs>W_]D><"6&C?idV1-DbolSm,e6I#]GEonI<IoV5MG3C"
	ejC2qaKVXs:8uKErTV7`EL''JLNh\fio"F/aA%2>ES33[GVGIpEC'!l&>AG5hPHpb-FQ+2IVP3_
	+q3?#gm?[;D)ECH9lHfqSPc&`rr33Dk@k.dLOf\c%`JYKKgX;/JhW/WOSpp3cCia+u?am/@T3>&
	TCupld>DBCQmCToLX/0lK1obDA?s%"!McDBF=Re]PNUS"8._\U<a;Bur=%=l/m31r%`<``AZmZ*
	>A[mhast?9LIp\G3A]EW)J'1[QMU]D),SQqrq>ICQ8!U!%n'GF%$uJ(IS`3HKR/hY/k>,PsCaqA
	aqtnN8u;T25!YIho2*me&!g!p2W`mO.h_mcFS)%c7$,1/0-Q;W`n(]?=u8rrAF5)`YqkDh!n=q`
	Xr(5!JJV`nq9_pleA&/G5PY=22N"]MEHSBD,V+)0b%N^%8o6KTItgkf9(3*"5hV.oV]kT_)r$CT
	#?d9cA(O:.npVX*f!eTB#^Inafu7p!3i?M)6W0*)C4FgeSJp^U4!em2@WBlU%,@m@8b;F&K4.kp
	XO(o6pno.<F!ZCJ0+(NSOFKnXoM&L@.0Jn;g]HT!pop/2Sq6d4QUukSg0?$&ko1Mrg76NT[H8fo
	#&pUNag;+*k?X^TN;hV"U$u[':Fc+5+-_G,O<4CIlutI7M5EN8>9<G+!E$DF9>]mB=]=Wl_ad0u
	e6<Y8QY))YDOC:<N-WHI1'gPDu2FI6[8ji6B=?1B.?3HjB/M9"36FCLJ6LPGc1K<`o:mP%[k%o!
	GCY%$SeSPKBsG21L#mQ$"sb&)Fb2q2/O5SftSSpm\7-(Z5bsL%HBi_]!-X+,@7^=PY?H]a!ajJL
	1ERA,1dhf7(ubmpPu!UhpC_V:oeBH>%>>2!![)?#4.uDt\GGNjg!s(9-ft;bmVQr(59nA^de=fX
	1EBJ@(^sVY_o"1.%JCYj/@GB9GM#GV=>8?<4](I08-FCM@ni7aI'DB)Pq-nF)8,X%reAJb1NUiW
	\bFiS?:_e#g"u4Y:3MNE)dYRRIk)dV].q"V+XE\rIsiPZs<c.S]9uIcWUb7ARNZrr<IS5K$>"ps
	[/GYVkm'hni6)hD1G8YZh&,_D@r#,/YVJ*[6OYDMYhJEP]`<`H":aN[p^t?ZTqu;PD9ND6`,-2#
	%+A"'PSqot0TY7+\<Ie9jPjW+_bQdIbUdO6la'`-=Xn/]'ZNa0gOd&;M.C935A6du>XgD%jLmfB
	$jC*BC]j^AHRNIL5p$nJ?fW!,DI:<4)-QV&kJl?0^#[Nk=:T$ZU6'k-/Ouc$p.th+&srLnm_a]O
	Z(d<N-j48]tBr?`N=*#dm\0\p+._3R?G!_ELK.O,07nM*(f'`#UJj_((l_jgF/!4?#*+@k?%QaK
	6)]D/h%X]4SmB8>h02;2U%.n#r-:j**+eI6Q\RZM8_8#4pg9[=>%J"h[^.l[BN:7Ark;:H]tX(n
	%O;L>U49cZkJfjV@jak9D1YFWdQFQ'uak8PjfG/^jP%G[KA^O"G_rn7t6!opoI*H@NjN22f3OXh
	6Pi?g6!AWlFR4Uo$;32pQ9XOdu.MPH.F$8L5`'?dI?s"URXZ`p3FAcEZkg`;8$XRK!6oqr-,&nA
	<km+8CUcYdV-*([MrZh'9jt,.i+p.Y_=eno!iPc8?fQW@i+75E\IF5I.Dd4NC4qR_33On;H9P[[
	5qP!#+QtGCCU^oXV=bU>"l$?ehLE0%(l"i^TMAeRUjh"*1ZgcP=jpl)Kk_X'N?op=%L[0iY'leX
	kZtkl1XihsBJ)!!rS/iBcu%iJ$^01u0cWHS%)=d-;N#ZTZIPibd-if!DX)S#&6-%XG3l(&=U&Uo
	jDVpcaH*C"]XXqOYV%B7)/X^*rmgZ26b=@IYDNV!:!iTQI5W=_0<=M>"HQgd^;NmTa:?(!hQ5WE
	"E?P>,ET26RL7D0m=PV>efmr[%*T`d\Y9ILr-gRao];Vd"BapJQdf3b4"=0XA[*LlLF@@V-M4N!
	"W8]#dF3)nNYrSu,,Lk+%U@l1Z6%A+5O]co`PSC-!HR]jp#,QAP+o=O[1PF/hof2=&8i`'m#6hK
	`6=jn"Kl3;0KQU2iiI8\$?sC1cE">ICh^o/"$(n:/A_-2;m7kCPl4l[B;PPMpr`S#sjo6G=e\T%
	sjTKgW,4mbK"IJ3[ta@hkf?,s,(srT)Rnl9o?q+*'9gml`U'pdK\.r(]o2*df$[rZoI.Vs"]eEr
	OKhp1R)&]Ld)NL6XsJb:9lPO2'/WF1SiYC3:57^RbB)1K@6FQ^i!%]T.0YiSVR8n(M8>nM'`TGN
	#UQnZCd#FU^E(gC*9:,`&`tIV39&N^:(@"CVk50Q7K4PgpQ[CZqn(?V>')KY=QHXflZmS)J"54D
	eg4!"'+O?7,GGi^dm7*h@<lEq3F*k-_a&D5L97!jOM^JV&N)$",d<9j,<DP)S#+CCUr>jGSrjDf
	`GeM>e05TAc]-2;.n/i@Ru%D*pmK]JjtW3P%p(9,#Ca89Y"5Q;XE!E]Mnb1\0+A\r`lpaR?:GDn
	2\Mc8'dje'kS<rm^oLpke#AN*[j\Zu:^9LJcOgoTmk3r?FjKM=,6?A8*CfEL_HJPa>;WETM`HZ8
	0<k2+UYtN2<D\=8b1B=q[@/'s=!l]KuESC6MtKe&GGf$.P<^"6/Z+qJN240Y.2*qb/>.@NiM9PV
	SOfqt(Sg+^-S^e!AlF<1Vg5f:27irEJ2ULa;N-ID=`ZLp^TG0ml`K>.F+f!@=8i3P5k>=Zjon=L
	O8=0?LPE(opYGUSQ>!/ZmUt-;\Se%_(?:ke%)r2!Q,0n]/Q%0-0g/o(0aWqS/"BDrJEeKF5'AUY
	7Pl,DcCOT^Zn2C5HC6@6\BVIGafGq^uSQR;&Y9lJDenD/&L_iL@U"T+^J(.+*.kgC$_#<mhd\dr
	G>a,Jb(Q-V8-M&SrZLEO0?G>:S!@SYVElnp>gLL-EmS7d7@rcgX.lC`[c)[qj(5$^2Ks,"C@dqa
	TZP\-F6AnQm$*l?\UUX,Lr:dYeIm>#EH1_&^V]:;B-d"sm7HfZm2G#_@kbc-J^<Aq11.+rd))O)
	meK6n]]5=\0`US5ZYp7B'R[lm<l9gYD\V_0a7[^NGppqS?4d<#g%sXkX=p1K"ZY4u+kfeh/;l7Y
	Fh^`c5.gBUSIQa)?Jl"I$kb5!-@NUT&VbeoeTIYgdPAF_GUNeDj@>#$F!qg^LBZ36sIq3g*.$8"
	.;/DgNKGOo$[("oL7IZJWQd[h*5e$.StT[^=_(k)OT!Q%@`=ab.?J,a,\0*"5e-d_)cq/!XdLn\
	=F/iP-AA`3XOE%:7fg'>(qAo(560J"sEF"U%t7NK/3qgD!,iUW]OMign>dMSHHXK75HN6h!$n25
	[oi6c.8%,Z*juYE<?.,]ePD.^$C<1";)J<g4ff\rENAfgFb#m%:/"f>lU+N-#RIpliKSf!/tU>0
	NQ[RPdf/,T'G<eEq37hRGQ>WeG(&o!G$fRSDSbKD'QZa+O;,i?'&!HW%84_0Q:)Po=#c$);_aF%
	J4Z^0J1k0fd:^05Do)/\;B@guCokUZ"FpHKD>g+S^SlpkQ[hL8uDQ+OJ^1/#sO?'t5\^4"6F=gc
	s>a"moCYjTWhC4b_(-DHkTi!,#YnIQm8A`SV&-G`HW]0+rMm>t8'VG7f,S?D4o:b?_1>PU[0p"S
	L"\eo>\pX_"E!$RV;aY5ZIbqSXEme1Ej0GeZuC^4g>SJp=jUid9F\=WFo73jKHB?.`)7Ja5m.C?
	q-foF>*u4VPW&(\#3+mGKK8*r!W/MeBRD[;Qao@AgcLPiUsu#TK6Q,2`G\*G[Z-<F,"d%4%(eli
	&Zdr$st!%^W3>Bl`L*94MFtEequamIt(K+2#Y@<%,:`aEKMb%pD4UT@TBc?%Adr)'=a0'kEN1>"
	#[&*bpNcU:_Ie>1h![N&-&HdU6=;>+5P-3@\iCAXMQ<TpD*/Djlti3=d#*([rNb=#0Q3_KoOhE-
	g;4DAI0fppb7n]-q1Z=B0)n)I9PEgi:r]@51OMWM]RI?b^Z6QhE?4,A0'MhA:nJgk:kgSQ,Rm9(
	_/8B!Pb17fH'YO!\!F;[7Ts9@co:cU%%r_lnjQ%-(jVXWL!Z)29&VE.UP#L-eNFpt(pi`+*e)eY
	O^CrrA2H@H_*<C@kJ8pO6`*UZ9Z2Bn2WEHVf4&*1gX^TNmqCGRR;BL7A+U1"FM;<.6m/jR;jg$=
	=li]%QYe25"40"390("nEdCHlcJ'(']a=EHP1MNi_iDB8FM'\10*1!.%u:rr=r'T>S.fmpjj0;g
	rkiUua1mD75Ad^&J(.`i=<9V\_u2*_"uR5FAG30!s/FI/Tk-:U7]?:<c,FWiDam7KTO("41,/X*
	84(.j\^TCsWt:5U3**5p`hIoVZ_GB&"X\.n:g>O9*[FCIN]*]3`H^6I\_J[P?p'A/4QjV#-"Oa#
	auUl/]f<EtBY8cbh)*:N>i,kk6g_DJ<d^bgk46U^5^h;kL0@r$$p7DbQus<#k)$or`A/JL#=bE@
	m4/$nX2=93!0*&h%qC;qD5C"m/dq[q9f&WnACKN70)8SM7-m!,ulWU>iGQ%C_H<$m.0p!''uYoi
	0f0>/dn]P1^_`FW\Irq)#1@=0Z?X8h#u<OF%)Uj\s=Kq3*1/@q!DM<b28r)6c+FM[JA[8Ye(]1S
	,uq(kYKfc8u@9+eT#Z@[MclJ,tW$)5%/Sc?mn>jA5nq!9SeGSBq=WkU6Ej1]V/F!+9@,-ih'T`;
	h:fO:0&_qG8le1]X$UEQp1"n)?RunaP;mhR@'tGf.AODS<%&`Zg<*j]FO%2W5VB@D)[em;.eWD,
	.KB8Z58$Ei05Ua^"HD@#EeTMC?n$O[:=,TiG&#!!(pW3XWg1r+!,7-lAUdn-;6M"j"pg.<'MoM?
	X'AV#XBEF?M_(\h9\PC6l-]l+2S\g>,t)S[-3!<RBb2";3/\imV+pdV@!TNMP6@)F]sYVd$!pT4
	J(.>MI2hZ,VY9'PFWM$;Its`jAc8_F4GO7VDf/"184?_LVtuIAd1D;<fU_";5dr?WmVQb:@c8<.
	a1/0dl*@5UQ)_Zj:]n6?L?BV.#IuY,?.I=S(iP7+Trg87I&<5.SX*.1tHBNB5RpWHUHS%SI^S?%
	^MIBWgc#%#X=iPNFP%+/N.T&SB);5k)Z5S+F5k!!kS,SMn;-]$,1fV;6-W.E=X3WgcUOM6D&h(,
	jV@!-FFk.sWs['[?M*6bstWgH#s)U5U;S%VmE9;=J2,C#PZrIad0oV"gFRkoM5B<gO!$GWWh"-e
	&dScJllV:R(FB/P4#0\\ThCk8ha6;MQL&lXE',\\n2Hii]WG0A48&AadO;/PEmF<^&:fD6-DLb%
	e@>b:M;UMUhWt$m9hBL0,JPHBY+UPut$OUCqL1f^HO1Gf/NZJc7'B6fA`.54M+A'Y79?h9NE>H"
	!Rb3g?fuJJ([r<[<P6^N"^3%t%DSNB'GWZ<g_?S!%qMo`"oLh\a"9iD5*[/=nnl8AE_<B7&V%Hp
	OURCNUrZP/=&%?S&QR<8?f[)jDGH3csBBdb.k=QC=$4QfI8IT7XcrpsJ%bpe.fuq0Y3^/K[WlnQ
	rO796$k5hP1s#P629#BE40F><[Y%V[AFs[B?*llmoJcC20>#nIL0JH)l<V[.pmj`Qo$=K>@>tV0
	+Ze6Tj(-Z.hfI;']BPhm*pn6eIf!1Q%eX.npN@4'q*?r%mmC!/\E$HkQ35iu\d/@[k;;f=1HW7%
	XsFL$eenOJBURYO<5p*1(Q>L-'$N`\f+lb!.U-dS2Mb>54rRc\0"QpuQMS9?D!gFe=StBent1jb
	L0rd>;CJ5"'QD'K^];,k9H>#h3fkkn(HugUZ`ZZ;8DG*Sc$CnR$nG9<)_F[Y8Lo`Mc,Wp9U[^)P
	*,3eOhpW3<hJG&uC?eII!K3A'1V_YKl$^;/^&l2soki%6*9j`[bt_QXAKK3\Q3ZCQ%GsLSm^j,3
	nn7&S^AY@-pp!Um(cJ.r77cO$@j`'.mLL4\+MdHtrFbq^q,Xk!Q9*q"Dm*eWU+N]Rb5tOkXg^rr
	DOLPn.LWM/?\1FV?S1(/KlO9kj.4?G$"0J)L4M"RCAkBc7r(\4I;lArU>%)l,qQ,#oMs#<C'Z\R
	?OJaa<\-moOQl`IG7u`F"L/.e%>5DtT_._)I!`Fnstbeb+rlEHuOJP1+]cN2g>lB?O5F^JNH!E)
	#f'[Jp5W%S`DG\&LXj4tcV!n?i2q_GK.DGF+bW>(V!/>-PHcFgrR0MJIJSZn8cL&h9JUH?6u#VP
	Pk$q:PjfaSL,S=87OM!##87G^EYe>eTY:di%PN^XTA1[CKurQ'AA,)_r16!PM5I);pZ.R\VrUeZ
	:UqO&:0)F<K'HEjNgh*3cFTc56t&.S`,W<6X&J=^6%X_4c](O\P:B1=U?m&Sa=@)D*_oE`=ku@3
	j1MV5!Bil@(51oY"GO9%5JfK'N%9mNG0A&Yk$!,UJMo0P6BFkB@pr0?Wo;Q^MT#CRW"goY!Dq*E
	qdHp@_tKY>*!R^_FT!H;Jsej5q4!f#ne74&)oJ3TYk1:ZA8gnj0'r]>7:Err?W`h!'!nQ6#"p@2
	r0>)AH5<1&Oo26ii&GSgl$mV#EA5o4>fK7\@L"]b34F`O\#+,Y=YYC>'\Fi+o0no7<:IX;.@G>Q
	u;haY[na1eH].MiAtq9LDr<363rE()g]IL10^2>XMgh,NnMKe"o,Q(MKos_S"*uWj3B"jm?'kVM
	+PVWCa2Bdrb:B$DDOP$1_Rj6e$Rm>.l28U=D$d^"V:.Q]/^Fj=pgXl54J/B%<<DBrd9'[tu^<#b
	^,J;+#6:P.>"o;k.B2\2>'P`%Pd_DHF[H@9%;LKrpq&_Vog2GGfF_XC3EaADgsMg7?2l_7*=1Ht
	BnInnD?>JcLYCj:3+kd;Z>C,23Y]5oiTWktfZ#BOXRrMhZI%g^2)0:ShjU;_>F06$E-GY/CZA"k
	do:7"L*oNdK9cPbq]Cl8_].q+mi!dkjcTb+%Ce[t^++6JZF#o4kj[Vf;?UFRf_a=G=/p-s2*P(r
	J-a_#ouKJ-d1l5&O(OC])D@dcT/\`%T.Q&RF9[H#]lu\iI+'efp6ZOl"ObmGtWfMC_[[&hoT;jc
	WF!g)E!iq\Z/?S(lJ"jSMF(hK4hKX'KR<jgW^@R*9EnLFsg5l;8q]c,\P+K*Ch`I&(SuhrEVbe9
	`Lnn*.R*oCaF/!/8n]*A^R^I?pWLRk='&RVUfu%BDgQ04bF'8U:'7L`EZ*rr@9*1%#lAPZj8V0D
	KpGc)Y*hYkZK&NAn^t7e9g1Vps\1]tBs%rmjWZm-r:sC%7oho$.FpIV/D>&YGH@3`0p@:>138M+
	QH&D)]F0'>^V^lXcieZ.TRj:nGg@Q><IRZJ-5`UA=MX1JGr9+DppRjO.#fAD?MHghq$,)P7PS.-
	o_4n99^HH`J(p;I)'->h^Tj,6%Y=\UgP1'j5,u^jr*@,V]$["B<YYN0JM#p#J*@dq9IE`m'!.e[
	7CN<7/,;jr-t(^XJ="T;VM,GpJ?l/F!UT390.$a_:Ec5:P(7-FR]>=0Wb5kBV(;.p%eJ?4PKQ%[
	3U4Y"Z*+C);h@ZEY>oE;<Q8M)Hbe\,aSN,_;Jr'9nZoT8?<;,l=*,Mt+hf^X?N@B"PC$mo?U@db
	RqNHO/_[S+V%3R4LWk-+]VZMpB_l+<@:M/JgnTG!nf:lMgjdcC;Z-(pu"4SL.M$dBjbYCb78g_0
	P0#`h:d*QhrRW:_d,VNZ@+"j+;<B,oc:P!)HNab2j-Cr*n5pUsNL$V8cm>.bNtV)5PccQKB$U9;
	nAi.2e8^o!UqADKRq9l,QlkY<d4f<q*<3h0RgGnE^r(fh4*SBjfY0!_0rTc,g>=O>(&IQ]mr?jJ
	-T@0PS\"DVqXlYUL1Ar+jkr9<3@!dS%oahqb`1B%+_IVDZ'20dLg"IS0tR,Qp+E:fj)KP20KCUC
	Le4n3=mOB>pJS[2g0&50ha%)/l6'R1X>=]SV;]Z`fhA_GGH+X$F:`"i8Gr.WLDGoI3ARf]VpgN#
	j^af">@dC&37KRomS.7;_/jH`0ZO-).s@r9_o`NJoNTTEde$\HbPu(5mTXplirS;;(6K41ish"6
	#e?/OrK]NCiMF\CU'mDm7t&,:q<LX8UJh&-Cd-FisegEdQ&Sqo\'K*cn:XG4?=.=p%-)Vd(<%H_
	7ZKg`(TG9qo@feR=H5R0Wsq84Flde)W%$f@ZnQrg&lqS`jqV59+g("kP,Z4XN`PA(A$OV.KO8O4
	bb?URL93+NGpj7gcctUY=&=,tVg#/U_s[k#NQ8]NsMKG<jW!h-3:XG1H!0lM><1[>Uih2f_"n8*
	4C>1E&1^!T+c&UgUo-7P2$sogIWEOu0O!N;D,-F5d!4e*Lr?[@9#&+_L=6.0Mt'H<Ih=Nff#ZQO
	/c.:1_jF2r"0t.;XrYIu[^5kdL>`nQG-<Q*$pVe#&^I>;VHXc%\h`.a8lgfo1e[g4p#p\-r![m<
	X5rj=YLX9)..\Dlq?&WbO^>^<u?@.;Tr/e+^h!f[J:65J8;?@dM3e`"3,5ih=f3d6%'tfR3DJcL
	BH+IhDI.`4d7url;=Q\%T9",aLH]A!V+W!1$2ah_8oP&m&b+b7nnu:+E)00i)-U!.^<gFu2B;r'
	ApkX,TbFZ./FE#p:.#MsV]SH%5#5._3#<^]8m"5:bg"h6::TV[0n+X7,6cP?Md<GSB)6YMu`*l?
	ZIeT5/:X$f7k:AOX/;nn7ORo,#Y`@3Ea(`drBSi,_M4e7+m;*+sJpSZ-k[=7Fgqr'fUYP4);ZZd
	u<:\8A.5r>HNAq,>U^/@elLeW^4?A-,I_"Xtkq?h""]RAA`.7!rA3I/5D'nQKVRV2gn@C9t7$R;
	W_lF[T>j;_l@';YeL-[?lliT<j9tqka%FR@50@pnt1+f"Ilu@i1P&Gi&")g0!qdf2.AM)lX&q'2
	$Tmjt\n*;]9F@qYpOhDGO4tGO]UiQI_Ar(O$oAd36/h<0dp*67KR$91d?!DFfk$Bg=>6J-)rSF&
	hS$oN-Bg5G1"uCZ\d(poi\(m6Ft!VV'R9+)SBhCE&)+(U:XLI!8e_pBC@5p(c9%"Q`1j:7Ms)p"
	/f>F#,.mNIEA*]JX>EW+l*EpUZ'MQ$SYI`9D2LQY&[91eT<Q&X^?B?8,'1%btUPZ&<d$^YhnpG.
	>"G(VFU)UTUA%AY;MSC"BbV`As)YEmnAgCco1a6E%L.AEr4h[j6@NHRa6GDu*NO4KX,!EXrc[DX
	gMWjSmJo_b7MR[\!IIYDDa$DOTCUo&;qdlfGd;2G_R@?%doLE(6(&Y.VLkOQAC-1j)TMIP[8^ZY
	L>CDes=!9eOBg]Wte]28,d0*3OMQI'PMl$9s2re52hJ0BE-+-Rj0/4V,>SXi@^*N<]7EqVP2^\Z
	pllY3cm5;Ro%pW8-%g3>jr3e"F]QdV.#k%HMU*<c&8-?N]#D_^(g-.0.e9gjKDA`]4f+8B2,,5S
	L.KCQ_9^@o?-`m(A9e*@LuaZ][kpqGRt<<qW<kW50@E<[GCDChE\IGP]]'mf^??;7BEi>-fWG&:
	oC8)^8[0;DX=-L[\ZdIhr9tr$G__dX4U:]KmkBY^%H2c3*ROB=;e])9O$/YcOGXX.P(E$bYt7^P
	$4g[ZoVc[s6tl8/B@VkigdKJdcZ=SGL[sQT$ep%4u!P,CCa*:W:L-CJPiC>>+K4]sF+L>sd=,M2
	tQ:eT6;3*cXSZ."!YbBg'MUn>!g=>PMe9]J68##DQg]oOsu-#dt@U"el)":-,!=F%]e_g^-4(=S
	P%_HqSY^)q/?-nL-iW>$Gt+:^F[09FaEtE&aV]<_E5iQ/LPMrr<OX*a!0c?5rB7MkaKkd52Z]CM
	F[Q0sDdqSu"t*jj#<tF-F4Fd1lL7q`+L(n6_#(4@,\9"$k;BX$dQShV20_aUeOSYG&uU])1#=PE
	N89YU#O6)X[$L^sAnQO&(64l#KmNNodHeHYG(La*g$lP!F$qE&jo[QB(hBrr@g]$@ETXO&!3in7
	RJ4cOJU`30Ih$mD9`CF=uBR*O9pa;O%/.E*@'bd!QMcmgEoWm]iR$p6p0*Y"Z;CS`RM2A\=-k$I
	Uk\!cdn/gM&%^/n2ZdA&("3X*5A5FK"UD<uURNK*5p0512I,PFoNfk9nm&=rpc'^Y#a*3aT;TNF
	0[$:6FS-7oo-`cFI_1W+j%)P0-.;*3n?$ale;JQ*dSdUnacK.3m=@+FG4!(W@>?(d)$]%3NMCfS
	j!llW&!+rot)I(P2.;4f^Qb;0Rr&4$Cac/bhEc0,jUm:@R,Ni;FTmcueU^/NRZ9&DDXhqlhf]O%
	a3"<+RJiVC(_Hpj^1b:P<g_9claOD01aad6+oiXJ-:q''D4]4ion`VV?HZ?']Sg"j#JF%+7ZTq%
	to#POp,M>.Xf5Beb^!3Y3#NOL'NLHI0p*ESOsOJSlEceC\?RVpBZ_BX\to%Vcn21>Gc,1f;&9<;
	8a$`@Y"S\=WC2D7%_Z[^4]pP2T-kS\\21"!?`RGmEg$[LQ%ngso%j*"KUX,op%\>$HDb9sW7@=E
	Q#<6)GM=agl2BM@HZL0TeN<i5hkS.kYf=7>p:Uec,V\l`EeEiqa[*8@$"Aqb,$#ksV="o%D>#Mr
	t3ea^tQOGtAh]&X%1=juRD^Hkk/D/*$*n96Dgf9[n28^[2,KjCujN;/n-b,/WHpJ3t2Q]/tXXK>
	f[#g$;&gZlj-p%/0@e6V0G#0aoinobjZ8\=[J6eDoj`K&p3gTeI#l4Z<$1eZHoU7WasQ@rV<beI
	V<FX]2B2iH#f5CPti?R2OF8D'a7^rrAZpk_CZnXQHM+T/&(pHc4N;2j(p9=aihWj`#J='qJM?;0
	#+Q`(A.<>+I]h&BHP#_uA2+3&GiZO^tK7_]XO\Ft34rSL>?iZ%jD"[.Y.`\i_CZ.?jkMJ]Xq*`)
	fZ:+WFrGO;nsCJgp9!:GOEU?%&RQ?^MCKF2@f*7'+IIkc;P?(aIV1P23K[?[4_XjbNN.AKf5'E_
	5\D/'_h<X`+dr5_'A/S`nIUW05uG^@;V<B->:\1QP6&WG*'9/A:+!-q=PB!J%5doZ,CCNV4gE\;
	PQL,@u&!j).EN*guYqQ1YqKA)2cS,R,B!&ipOhqGJ1Pe0d<omr$E8Mq@:`9LFGK3<KN9;B<\@&7
	Ih$P($8gH^Xp;;=%iGKc<+8W56e-,(Z!Om2Fm#Fop+SCUas^A6CIdUplUkFMjdW*:u64g^7cdl@
	J4QPG)^e(6*++=P?8`VqT-7MBBP6K:Y_HZ,n8S8L0IETsie0=^&gWX5hM8kZ9g`GP\_T[+ZOPl?
	D5QF(oCd^m0p>;rtbhIT+3`KV`H9oI$%Wh<\t7l8ErpPr>ab_CI-PG+GcO,26Q7\VSrG,6Kn--d
	\<??.fs>C.huT%]=#VGAWaUQ6ht;$tW2S!.k4ON.O%Ld*gZfgrImV!N#$Ar;+?/?;7B>Os7<qeC
	1K)ll"A#Fs.TXY&XEe2uj;p2V#AHQGqZ]>gr=,SNSW!5sD2eQ<(tAh2JY)AlU-Vi,(sFYbN4a'U
	!;k\cp[':#atI.kNPUNrBp`[9963ZF[FJEH'2u^o\G6?5VknJ-dJ%99n>1[OV5NHfD5dHl:m;"p
	FIN\,D"rG:qW^[^_VPjH0Z,jTonoJ]hF5O1iMH:,A+.(!Phha'$"nIL4Kq8A$IL8`?P,mmE7&[9
	;<S,>PP$$%Fd&`0P$e=Ksk4NFt71-dT>C>$a9/>/#c+Y3FQlIJ'S2hXUl[\3LD-`k[04*:tU#V'
	RIr9Pn-+9.[@4Q82]!&6[b_9(07N78QW9j:6Oa]=1W$F-h;f_Fud^)SPKQ(:=USSYb5U3/V7WFa
	-q5`W;?^*8hKaal$1%AU#i"Te=X=B2ia!eJ1be1`7Dcm2Yf<6?h(ZXguDSGe_&*DS+q5CJ@^H/P
	elo%7e>PlGU*+@Lq9cl&7%]U<)*fh"<P"N9qRdp)uE]A$E81/Q0U;:q+E_[*YnY>Uo5QE#9-Wi"
	/=gZa$D(PF*6@G=5Sa4*N#Bou/G8L5;*8Rp];W%!LR!HMo=r.gePq7Ks?C1"SR%!J31.$5#T*Zm
	YnS4Yc3g9EbQ@.QR3u!gQ*^A5])g_,*B[F7l10AlgrO@X7$`ZiJOS<2!;?_eE".,LDKIC&g_'E#
	3!A!!'gM"/)Qr[h-K:!+]+2[t)U2)qXEE5RXe0S.+R@a+%7o_C@#EWhDqWN!`rS,GCnf_/_VuC6
	0FGDOc`W$5gnEJ:mH'qUF;7&kO94R3W8]14#An;RjB`aFJ0RHf+lce$,uEf.FaQ&5T$X/-HT#p<
	fhp.eCY9RW`/O1[]WlCC&#c=4ThJ._/.5.%_Eo,*Nh-H@S:41];(!"jUeB'AC0VDCunsNWSAK);
	G5PYGEN]c(NjY/u7()V8@,(KSk#so1hhRnh.g8k8EI2ZY7`%"4A$u^n:fd!T&_7drA."\=Rq.kc
	b<G4m9,Q-ea"5fN/X>MKTAe2]hTn<uPsHXZH^)qb[:b()=iYTKCW,>`Go&kXXf)KlSNMcT?h\Kl
	Xi8WiATOM!`W]KMn"9MCX0?iRZjL`^[d/5uh>u_S>W3S\;q:Nj+NY9/k)8f5G(uU+;TlLW%A_$\
	K"tRTp9i^efKLa<Z,m'l"O2aR&A'BYe'[@%"&M(@TD9L)Y/Q>9arZ/;q^n%hr,I/\uf8jO18;^B
	NOT_5V*l1bJ.)*jlFlF$_<j)D*bhIQZK^Yj&,uTT*YBqlMYN8S-7*q!W*(o?1!J'<?bo-J^:VA*
	-bpO;sc9D&.E:M62/>Yd:sGPO7'l<`T8Mj,ZWU[>lM:FbQN3M!gO`Qlh_gjc>]c-tq-IUH3=O^C
	u!%iI:uD3f1AsHo4%C)ns%O+h"bh]c)i,7aX^e0\R`jS@M'c]4`KG!=*,(de05k1AHW*eZQ:6Mg
	MFs88_tHdeq^$!A$\fZXuI`0TJ`[``^Dm^n<*U7H=s79cO*4(OTi'QZeR*XD3j=%I.Z3he<[,b3
	/t_)k4]@-N4(J4/$+O7&f&%9gta_`#>8de@pi=nB='?]<IUXhVRj+ehfe(eK]lGE*Zt-+=48K=8
	]=4("n+#6FcrQ(;0G$CS4D&,kGahd(#+a4WjPZ#d#-`dhYE_)h=#0\]=fA0'o8K3>H_VA;9C+-h
	sF)VM?7Khd<tC-G^L%mXugV9924<a)`5>K,aqE`E`4a-'%T)5q^&B^\C0qpn(R6ok!Ye3euGVn!
	Z4RYH6=%>fX2k`t$X173o#TIit##>T2$AM+$a%hB&4N%;WM>XB#..;).kTD2tW@r2R/8lnKAh<W
	T\6++#4am>A$&Ytn'A@uFAZ@Lj&!^o7..O&!^&Pt'_EF2jAA\i")W8=8Ko^8kA5RBqf<`H')CSo
	I,W`2(e$/OYZ6F7gNAc,6ffC-JK(ViG*A'A1lR/K6,c87Dgdf@m+^,+d>&&>Y1(:L*RiSUmi0nn
	:9$@@%s^a8Z,Xd8.<BLLQ59ZG>BjN4t(Vk?94(`bmAG$QrPDEL&b:Pkp3`Z=R.\mK<WN0D2F#22
	a$*k#LFaG<IsbH4=UX4Ku`=5jg[r33#QT2Na8M,>.'LL#W.6`G1ZsSu!YV.J0Yd[qVcrOKFZq*(
	s27U6@);.m"Peqt!?d(si?FcnGUL"+d7(_*0]'+7Yt\Hq33WHnr9$p)Z'[bT7_:Ro-h]#rKO>P9
	2q";1u`\mIFg`jW*3Il_RJk;<Ia.rhhm;-KT-Fa#0oHbe>GchS6/V[noMoC-%B^T5$E_k[.)pd`
	oJ,77YM1\-V1]q/NnWC=RR^-F?hNe%>M\kri3urr=7errBBtNhl1dU%V7s/sW2)TeuJ(("B?CYD
	?_n>8Ne>nH<2U*9YOX?ifDD?5?UDfC6Jie!9QTnFj,PnC.)3nK*r;K^HEN3aHFm3paG;p6%:Y-%
	mDibUCm*8BKaQfbuao*,[b^K'.qcS!S<-\"EI'1n(iG/bhF$Gk&M;WO*Rr=@8c@Mdb0`:[Ml!DQ
	[ihS&Cgi0%:L8B8^Mi%>?m2m91lD%op<F\"G3k?$*d[!&KIMf`(s2*P[5U+)#gYQ(FNWL[?IoSd
	dndOsQ-3\lf\FL"[llN>h15N3>K;Aug0D3D*"Pn$eV$.T/hgmJU;aT8PoE4Ai'PdmESCKa"UGop
	1egU/,QEW&C8'`Gj3hg+BH1EX:c-L]`kaWtF'rC!J1\1[^lVH,a+3;=m!9n+LVnK<=@+o_P2<,E
	p,fpdWk*driUAQj>>J[g(dX:nS#M=Q/jpm`%d"U"reIRRq4:mJ.Xs3P2`m[>[acfdFaBQ\V[oFb
	u6TK2:+ucXZp_+caS5jXl1QP[[2'`HYp@@"`.5c?O7>)r5d]m<aG\m:YR'0Ddt]6+QO4eZLbK=_
	DAMhd1/+iN>AhrL<M)d_<k*atYaKONX6WZ+?jf;rtF$<qF#nq@D9)p\qVRkIqpbbC2SCc'O2/RO
	p$ZK1qWLL@349=e>=;frT'RbDZB#hP_%-;[BY,_8df$[8X782YXo]GN^I'P-XIn_!_4&ArhJV1A
	G#3D\-Y)0%UT70-Ch=YhugeW(Z<dT5&W)0Op;V"Nb78,]m%fX&b2-:g`]SMl0<Ipl8P,p1O/SAZ
	L'2`):@(/`*\jbqi\1egut?(R+R305LQLPNRam,!hGfW6^Fp2XA2U'XUoMbC<0JWCp:KpG0B!n6
	a4[h\ig`a<41sBR8O(Xl;:hDFB*1/KWb/Xf^uJq,9^-LR6("<liFB<3!jhV#%!c]_d;6SGb[nV4
	i@[*tgF1!/B>UdP(8JW9UjU=L_B$""h4ad'To$gnCAdR1#nUglfKC=;4Y;`7*mDBXR*6OHh9cg$
	e3SHf4ie;:>@gU06dKD#19IN"FgQQN$q0buiI[Qb8X=OE%doNj\#kV^C!8@TmM^O8u'Y9*tek=A
	o6rm\U#G_s'V*0L<cBA#1:]jsHH'K8u/rF$L4'aluC$/-o$]ca?=18@H>4j2[uHKni5V2PUG@39
	d#JZX^R8H]:=$KJJQiiB\HUTVopb@_5,T!P"=BjSO?g.>V%oJ286RVGB1FC,7MBe75u`)%;P@r4
	Isq['!&7)/tE_*41a,_N!UedhSR<YbY+td@pjn,`HblBag.L[Qqg@NSLKQJ+]dsIu<o"LVoR>hI
	i/%`#*>[3,QG>"5hJU;iTprW@rCc8T!KU^!oA@P=&o#"q/$i#WMsWr2aoK5TMAPC>'NA=4HmB!"
	F2(mc*roaom=S2on,UANKn;rVVuXO>H?1Z@]L0W64rWFoMH[4V(5-'UM.#!g5qS39/BJZ;fo0*9
	)^lnIJ!ZapiC<]W)iHf-^]3B,RJtaTjq$Oa)XU]PKl^$^8qMDLX]PZ<[R#5,A0lISfM-;jm]#Q,
	2W?d"M"HmO?di&DX;YFo:O+/!.K<JD`>7PjBoVf?9-9+'L3GQ/o\Y:;XOT?67-/NE([Q+1F.WE*
	MQqK&qLLOd"nH%QN`0<QZhX#,8#I_f4qf8lc=fo4gd-)1Z<Y)btJHWj&X&QLN^"@P]i,(bfX=q1
	khCo+b:=G<+7DI[o,Qg6lQ8c>^)7=a:7Wldrg3Z'%KDmmWLF9AMe`<k3B)pKEQ^>Y<l-MX[C6;8
	<7!YGk/^e*`u4N:G/5VJOOF=OLiFi(G"D76)U'XlC[:.,;nS]ju>GE9mEQE,/unoGnF;l*Nu>X)
	JM0&U%nnhN_N.MO'!VRls"VA:[mj>%Zm(i*\RaAC7,a+n7qZA`&*@jgNTZL=S5:ddOS37_+B^iJ
	-#%Ha?7.A%G&/"uF@I5g<dd@p#e"*sd<[_snOIe+@h2YI@.4,O1*n$[0(<3/m,lgd\-2JfVmTe&
	(3fT/!@*Su4.>!#j+sKY/h9GcsKDnSS92PM^)CIAWO.Xd7<UZq)("o-#D<.Y7$'A;'F$&mZ!=+5
	12Um0c)W!/<??5=Ch"jp:WAS!\b+[^hD+M5H4"7#C&]41X(KO>&Gm2N2#<C7*tn^R9I.IsIq<]B
	UUR5mb$*NWb`qP1br<Os;Ga&\J01b6N!kZ)IZL2k!LDFe[]:,4Tg!$Tj>@:pc9^[q)tUMC>=X-0
	X^=/cl"_j>eAS@_%,UWI+MBC&2p+:Ntd0gM;40H*+GDCT-%GaVEO`Y]N.T#i+^\OMn<i2ZTZ9@E
	Kn*m4WIZgf_Unp^:$11JMXsk2u@f;\dj#9X1JH)iT&nM3B$(OK,`[#;GLV&).I\QJ1cl*t)j_g=
	\a2nY/k)"j"-!K+Yueg&c+HmfP,="`cuDKk$t+r\&$_rrBth5Jn-/<,&F&f[O55:,uM5`s&R7'F
	;4110lO#KFgDi))S1gRQU`?drLrcfeXt6B==*b4'7ag.odfPKTB6GZ^"9W.WRIh=3@>?B6P#8gV
	n>[$]1//If*_W?H,WJ:MV#JK6q*I$RY$1;4m/E/Crmm6'4%C$c97K$<;,gRCPb&aQ(dC#Ep@(6C
	cMHj<[\MpbeOO4?T#)>053TZti(A(9;:,+?:;<nAT#(aVq1AAY%4.aUC\DXR+1aK\7;g@Qb!pW+
	]dLf\<@[@%CEudh:a@=finqB$rHr]8A#G_(hJdb3\H?*.C"NaZ$bgP$8>9.Y9Wigp;`DPF2@M::
	R=t/WoGKmSoOlecR52n,)kZ!8"5M-:=s<Uu!oV(U'Dpm@XCY?E`Yc-gMJhEd62.cV'K%!,TFHoj
	:e!0<A+D,@;JU.!b\TrrBK7rH^Z2:d2-X[r(XC89VkX`dd<@rr?B%iT_2`'`?2jn[=lfEAIXq!*
	oO(qXp&G1IYUPe&L*PRG-+0J($X]]cP%%HY<p21=NgHDu9;/!8"4D1EX&UUW+3trrAYJp[A+^Y=
	GjbrN$57([:r"o\9BDrrD`Up+m4r&]_m0GT<-dn)+-F?B8SMFeC,[-9?@PhtQU>!3\ntR!WKOr$
	D2`F#X'prrDB4lt.<m!Zr9DUQ!It!.OqJqXf+PMqYsBpe8'DhJ`;crrCZGfZZLc#EKYbkFnCErV
	lljl$FkEm9h%*Q.UT8?i0Tt!8""!83O%Crr@_Y:ET2\rrCe<rk0sr+o=fn-]0GlA9m),n,EBk9A
	.O<dNjb1>8HJd+8]^N!8"(6j?I>kFOr)]E$bMa^-DJd\Kj$lP,>?th#rN4!E7([b_U/L8Z#WICN
	4<tZ]GkZ1/I(-;j5iRif'<)-[9qb#VKbXZ:6'iL``2lC\<"EN;^Bp>N2iAdt8t#[q.JqT@T((bW
	WTEgZ#Yt=)^h2^;"5Dj%%Y_j=bE^12)+\B_Md<?K<cP*IaO,p(KaZTZQ6a`fB(CI#62>`("Hf.A
	?W0(1QetR50PXj*I;;1&a##3L/tU=A<\Y6'X2Zl&`Q-3aU*!kD9-<m7U9fc^GZ^'u1oOBlYs",.
	6$\oLfm!T2:7R`sO)"1\bR];Oc>Pl9T=-7H4gujiYVe?%F-bN007SV&md-KW;l]/Z,pk./hMY@L
	`[(4QG&.]h]kWND1&'IiGQQ=Wn[HbK1is*3=P/Z2LY5$5[k8UT6QY'g.XhkD>aNj(g%r>1+6?V3
	+5N5mAN?WtI5`<N7fhm@kV3T.3OXrr@b4C*K,+;)Cn8#[%iRrmBniVJAt8mpnqs<k1iC`mu(-TO
	>/_cSg5p$-J=t*1UO:.buO>?'))+DTLY'`0u+fjKV99NbFasDu`]=:>DF[3@%Whc>=q=DeT@AEt
	\B0[th?S-'doR+u"t@KU*m88'l4$eZ:o'm:/)2VNomr%9rOYnE%BfB`adg5puD`Cg%rHakUsQjE
	9cmX<gM]0R1`al=B0%*5"K\H'5T"1)%f7k6(=UqQ3O;I^MoE.)k_S_c(C(f:be$p=k##fBYrWWZ
	eH<5;B5/LVm"Vdj18q[IL`mps6EVH='aP5HId+[.rJ9WNAsY-19m)BH3L[]'<)7N;YsqlU/Qhnc
	alIqj`G"^+^pl0/#/O'+`c+<4HM&:pS@N1%P$7:Za[?RWLPQkIJi8^GFtU*5pGalP%MWEQ9:kDC
	&,;+XDYY"#*^X($CdP3XR.?.M>r)rX8LSQF`rcCFNCa5p1uK$K-qaOu)Ad3h"2jgIAHLY@F5P`-
	EYdlIjU/8QIcTL%WbfYI-fYDqrbZA%nM2h+8^i7ce"lqY[niS:@+[0<7XHLp\4Cl.V:cL3n?fEe
	NUpj#eC4DM)S3Z5TmGZ>$9UN]UYrA]P.#o=&m+GiH#C)QT"UlalcFr82.NpEG)<],cccJ9]+`]o
	Q#ZOpe]unH[!FY\1DQgF^VT,`t[?$4eE\E.@`7C*^5ads`QI>X<>\EPn/G.5>H\Oe)f,hjn+(-K
	`jnMI=pT7CJ@.*Zt'[M(nIl68:tYY!2<mdFd0K[k>,Slk)Uhjc;hOVq=kiEEmUsr&2nIe'*rT*%
	pBi2#0K"\FgSE1>!u3V(2_fReWg,&-2D&FBC.l]Xe`Y#i2(2Y6Q*<hQ7qW4&WSu)LUFM:Hi`kOq
	Ag'bRSrj14Aqt9$^@>o$7ts:/*B<JmCl;eCIiPk7T/,huiQb?.fQ=TG*mOoG(-Pck<n:pg;'\Gb
	;k?i`H`b<J!;h?K;hC/cfQE^_nMi%XgCfDkU4:dWfiRH4PiVQ9?TuYgqmE_44Y'Z4tVOE-N(u#-
	cU-!56TRkE)e(E':n5j^E5XR7e'eE#iM*X'[k@%R"Qj-)7![]Jg8<RqXF!amE9OD&Ki1;u8W0+\
	@n5:-er`9)B4D@LJ[%NY*E>J\W"9Ymkh)_lL>XN&$4@eW!jj\^X!J-4hsQ*dHhQBXGiC8#(<U`Y
	s49l^CkHY!E^UN[sl?:kYtj!Jb[2*=1TcZZ/c]Pe/_A_`B`3CitSW4Zc0<ZIRYTL$l)$<0<pV5[
	9?%6m"j)6!;>:)FdE0WVAEiRa.+2V;GriIGUH,g[4AS[o47lk9WW7jQ@P(F./+g<S8Ys(=4[NjF
	V4b:R2;&jW6@h7TN`Sq"Ou%"A/N$pq+qrLNY\*2k``^pB*q7`:"#ABg0b/BSn?P%ihak<Q@c]*<
	dF`YjTZF7tEcQU"Po042\X@Q*EoT0gfcW$;)")ViF,t5XFZI7mJMDU"tmfGU(*BefrE"5gs>Q<0
	B+mm?"?LOt;Uu*,]n#3;t3/W24$)fd2]4]K`5_!a4`q(9%C&nLR`+2DeXNU,_G-Rg6C^lUNE4Pb
	e(ui@/YubP5jEBuCHq*82`eV@4>'EX6k27q'c5/;!6%-\c_7F]c%1dVPCNMJojlGN>rrZ?\bgiO
	\3q<DW?S*JG7:RS6(g9`\.*JK/WDd4H'1Yn@HW<i':b)jF[EW?YdneuE=7(D[jV('P"?V-c+$jK
	Y\$41aCTq!Ml;MG[r8Oj&8rmG=`6%TN0K3atV\"L#+g?I>G>=!&3Jb'F_Y:1I8W/]R5cCe>'FZ&
	VAVh4I&'FBK5I=Cc:/J3'-W,@*l'f3ZFOes1u"h-"#KZF.&:cE8p2?knOl39k9Ye(i'aoJ94r1p
	%1pjoPQmZ6:),g#2l1or@ZP7Ck<CrKX0n*38m0N#sTjT:r=ZPDLoW3>qSJ"1_uU[:Hj7e.7hbi+
	l>L><NCd)>#qY]bR[1.4fBNrr@2.(!ru<@i%bV$]R)[S1\QeaS'0UZ-&-uVE(^?9V5q=7'\5p5p
	,NP=%n"D(2[TEE*&S+e@(6+Q^2#uE-"ii@USB-C.:?2G!.7`lqSdAIG19$fL$<r(o#tt"g!Z-%"
	<f#0QN4[3JkWb&"u,6k71D<kt;_&=U59<0#mr&Y=ah!Z!=t8.:f-7E\dIE#<DIUE\0]'eMYSn8X
	Z9_])lP'0uk6S_#4rg4o//,b$(Jt'^Wk(T`WkBG`bWM0a"f@+HYad.4;[pe!aQY5*mP'eh,`/G'
	b+UHKJ"j&<6Y9Jb,LR`?q3H1tQ5:?+_jBZ9\r$A:^(s0o*#2e#u]h7f!k!cg(KmO(j3rAALJel%
	C@0mEaVbf#j=[AEn8+(8Knq:@]`#\k&N(5`.;+i:l#RercjFd*:((l>nnU<Qc-S7E\6?Yfsq&$0
	OEOaYO^To##(^aCKLROr7Tb_"ZkOMJ3^V$*r$USgXCtDIXM\\F[^'I6&HBHAII17ae#rhE*<pWQ
	+GQ:>R_NC9GNdCfju>JGVLBRq!<[,P)?<pZn9&YGl6j@q*LGO!#^QN8Og3E^;p^5=&GqPgOOk=4
	6A2#hjP47/Y3(!"J=JN)hHqTsNnHBitY&P#%=\k61VN+X=]9F,J691e*2UOVI=6(R&Rs:.m,!]s
	,c1nEX#tD_dh9jAUiOH@-MNBt2YdL!L1N(j=g<LMb(jFmIVN4114t6#Uh<YY@%,+L#%UW9Wrrdc
	C7glWLr7eBo\HOX-BemUKi:TCl$?Vs8aM/_hseGf.JORSB041qJDV@HOptqq\r<OB"R=_)8&K7S
	cr4P*Atp4O_4j(@H=UmHriE((d5k9TkW"/(AURi+MT*CUt3)'mHXp3qAK?d&CmAX6[.'1>aqQ1H
	4b;_S4=5+<LIXeU'9YK_n>(fd(mjfButqD5+JEZAZqqCSU#Rk5aGFq2]D_"YO+f]!1@<db5pQ7e
	'3tk)=.>2%3??KJIh7&0lc\9($C!aX#s85+hr1Z]nl9?>S%FS>0aJ?goDiZl(-t0PRg`pC?:3^V
	*N=]77Ga6KakgOJc/abO.egP=j7"g#ZNo[3nf$o]D^I/`-*d$ZQ8cgd#7&#6u.1:-GYP4XK01a_
	r7WT@5G*TqC^-R*]CINd'sG!G4=Uc:@d:Zu!uTWMj1!lO_c9'*`Ke+g;M!kL=mWNnG+R9gb7O+t
	Z+qRO`g%8:GEKFApXPk;iGr8^"A2--L^"TWj=0>CHX5`,kVFWO[Df(nM8FNm`>Zp*ehC^UnbkF-
	*Dt7\j[JP)Ol/\S\=1/^R!YhoBf*/Q+Ud:PpB;\OdTZP&ZR=543ar'e<ac`,Fneh`Oq\)sN'hLp
	;5(YKRjb`d7=GHL]T6V:kJi-G#Q_`-64d>$^f[]6:f3U0.0cLML`ecca]8!&$sOY*s1L:=;i]eS
	T\(/a_)Yg;E;4[u`etR<BDII%u]`T"K9M(Bpq%9hTA6]$b`7*^)t#0=%"Jo[jOAF#+!ukKH`E7L
	O3sa![$#(8Yg@2GQ3?@Ss-Cod97_k$o;intZ0;Xqu.>m>]/a?c&!u/Ol>,r-RHglu*;=>fCO-g/
	qTI-_(,94V0;!ZTdP9pr,p:WD])<6*>H`6u^nT8IB_nE9;<e%d^+o%_m'B8Tc>nLFM5]B@Hc72=
	nup]3X2K$:tEW(#+F@c8+1->"6chc:t*RnD2l'fhZU*AJ1BfB'1Iu"lT(6VmUBaB6--"`E/C0L?
	OSpNf_*b4"inHSFQtre+KT5TK*s0if.kU=DdIY9u6E5:e6,2J9LnH@.bN4brEY.,IFnhQIOYZW&
	e[;:ddo[\fs_9N0#dq.L$*&qKH2X;-_opCAZ'9V;9g-/\H:rbkH,2cNJG"QiTE-Yj6u_Plj/@V9
	@Ja=6Ra>a-Ns2`pROmdK3p?aV-4;5hOeEPSQHr]d`L[R'@HcU6V!RNoF2_ZmgosK8f3CEW-0&;!
	'L?mu0FHn7JG0VX)j;@AqtZRiD`Q,cji*Bfc@8mABrUC*qsEGqu+aSWZ)G`o".4Gh^3dfd;D8hA
	]@0Xh<sc*R*u2[#HViGmTJ_gQTZuGfEabXTN7bGJ)6BplYG@C)Y*QCS4j7SK?A%Et?s+Xr:F(DK
	_<NBIBH8*cf/UM)R$2'r.ckpIk:Jink72?Y\&e6087URb.m=.q:!oKhg&]lJCIL/J`s#C"]*0W-
	hn@#-2johHu#ePP8-q@B)s(Z&s;0d]tk`[r4:fkDn\j--&?cN*esEkNt>Q4[JI?7YBfMO-Y>Q2W
	itbLA],n+N_9daMe2^8?,!h+0=cAl(k]VA-:@O6*?$ER*""=Y5TP+Q`Ro)XrE$7:XZii4!Ta/]5
	-pT3&2`_8Gg3197]])V2rPAOU+$JOiD/c7+*hKXSbl,V<,AUk![%V39h#L3uZ6*UGY[?SUI][NA
	b!,EBVH0bf^lTJ]b5\6Op,CEER<FOeqrDG2=au2%-a/COZK8nl8]1c[h:@ESdUYV/b<-`SkWnE[
	kleJmBAhU;J>T=TbcV$q#<Vk*:^A52/iJ.([Od9#+%O\>$kO5<\3IdjAdbBu<ef=D#sE<H2-(..
	Gn0)D3NVU"W&Yk,#;eILoM6e&S:PAL1gU=M1IDi,@O(Ii$I4=*N$>b1`()dY4isfCr?SKT2aa(m
	E.&5rg7%q4"&?O3X`Ml]iW6,jrH_EQoFu(XHoJZV8:C^`@I9"9/AO7CmUP1QoHHae7AAh+n3mGB
	#p1A;_`S].,PNA+\&.f'7psAj4p1UPJ@ua%>^s4I7rb.q^]%OqCe<.0fs#*HHK/cffS-*@Y`7.a
	>(+-BlC%jP$E]YGk*W4$Ft&GEtY;pH\g?+T<B3X][/Vj`c%+hXJk2%=c=-?G@1\+b73aU<;+l-n
	^>n#"%d;mju7^oE3sVPpduO.8d&kRcY7O<:LHo?s,A!aI>/7Rd*-oSdke]KA*GJa.T%]\sj`cnM
	[SK9+-dml7gmq`"kkU3*A.u(*U#Crh!A]7P0!;j[rEV=^!J;X`4W$dm]<og2Qek4ocgj0Q7OrA:
	"!dU!qV4<>Dr!Da#R`5M@Q&CnBN4,[g1tAKOTeqG=06gOl#7Z(kg.l(0)Ef1rh[J;sR//BBo',H
	s05fT4%9k(gl4b<L[/ZaB\TVF5)11PTV.W#b^3#W3*-Tj4/3YGWtZQKla'c?@4-XP#gg_#-o&4j
	)h(2(^$&j@Sglb_c$cO[`TR)9G#rMEU^66G+(nS?2_j(A-p;)HF19_Qo6pRuP%7:3Zk(5:kDVYa
	+rCrOd?ZR/[.&Df7!f@aggfOT+Y+[3leOcK?;]7RuFa<N6X<'/Oli5D9EBr*@okN'9X=,F6FQ'd
	^I#AEU-^kuP%\qO+ub:4u:1&&hFBjbm?bmbKf-V,Z4dOb;IUcT*!UHdh[fD1708CA4uB?gTj+mD
	$%c>rg>+Il9s'[,E2L`WcejO?R!]4GobSc]PN&RVSH=WjC%i+i<L_?&bTjI&0DG/:Z>RC`i2M=\
	ejkg".'FAs_@rEVOEeL]^;L>rEKFTnQ;mrAd)t?cK>DM/83D7e^I5lhd%aU5BnpVoH9cf'+0;./
	joIG7jiD*p/cX]uR;!@u8_7.X6/2nNDVr5*pVDaNqHpbheGqdRN(g8]E_L:ijuaS?q=gA9180bo
	Gbmdg,br/I'BbQJ+nU,[D9T9,[kW._ss`E(:&$Ar+pJ]U2<7d2)Ah*k.(cCM7Q9jj`Zi.Cm!u]3
	,!--fuU2N,J%?OpED;r2W/0<1^!bWH_n:mVP^gBe7i`840f0_F2eEjIMuHZ,cT`j/kh[CNNX_9T
	XW]\\4L@C%2a_Z3P<8/cj,R0qVp))Lkk)FAK,:AnOW-paY.[qA\l<,aUDA,IiaaLssOWS1?K'*=
	pW5.o1"@n=k>i3jNEU57HAbhq=>mhn"C0*E<CKKDim;H=#0NIkUR?ls\B7rr@R@D;\!`M+kK+-k
	FPiDe4?Lfg:Yo%Rs%W6`SaF^ja7G2)O\Z:9^#%hB#KP'(Xfj=]_g7luG\C#!)CVF.<%q-q/QJT@
	JBTBY#sgHX/9<Y2IG!\<\<Fq+f:b1WLL.VPpu)A@eaVN_`aTX.$llJn[-+b$/X;h"dGoN"cAU3Q
	=VU=tD`"aE?4i&Slk8[AamY@^<@sQMJIL3j7"kS7H9s`DWHOM03.e<i,=r`B)\\\$@`&QMk@(La
	l+HVqk^k5pI@kk;>kr<j,AI8P<n1;c1="%JAi#c[(p!@g4#h7P)4C$-:D<Fu=G9@lJc"6YR=2(i
	q@`JOrKef6>(FT=Rf')<8.de(e-%UsV;=*e^tZ/oB_I9u@OFX>Z8m&'D_m0Fe-_Fe#.H76=WDh&
	k[a/)gkWTBtJfXcPBKG;>QH#<4q$bWU9DfWJpcde>dI<F46</!#U;*O<;;g3^pc\<Jdc;N7qN5%
	hc\\^(9I=Rn@gcB,V%`.&#:fd7)PD(JOl(VbZ%2VjHQZi$qq)ut;+7jR-!\YCb"lf#S_h-?=G9@
	5)YWJr-\Ij;*4#Grp3WP-r)6aA=JGW3P:>KC[Z4/]l*"*sc'-%P&hG&pRE-h`s#&R.[?jT=9@*L
	[?n-tC6-Lt,#$W#Y]a>Ie'q/ZJ"HkrNt;N-Fk_<Zl9u$om,]37tBQ13,10i#c.QHd;!r[%a[DkO
	0GWG2MeS?eXa;&W"M.$su"p:j5+Rai>:sCX\'SY'H6+g-muoYgYH&BVD!Z,DQ*?-3d!Kp#eNG?/
	-uo0FUkE3ih%1$&q5Aj(72n9??Al8RgNQ;6gR7d.6:\Pp..`k"ln'Pd0/:oYAf99?\;i6<hY'AZ
	+<g@g`u&-dBFD"S;Fc[:(WuSfY-tIY"C`2QW$E6s-o[R#T$+`1!Rk6<5>CJ]EVu;(S37Z!nr<5;
	RRdi.*juER3-7-Y,kOOX6OlQI\*E'<I$M_7;hr;Dr+F1P*'!:,2"*8kl0E4Uu+%nQ\<JP%gA*mj
	iIX7:\^(F+YV`W5ma:n1&Ug>9fU.;*=p7`tk@d(eG91,IlTc"L`B&m>q>h0qVXcX.;habqFf12u
	::Fp$9`drmqM>(s8dV<b<f`'Dt:?hki@Q<`L]X25bYAFkRppHp&IS>>"X!74Dj0AfH0@!!K:a)*
	-$9pT3Ho4\]E7Q[F4,+,G;$QC;X[-)oB:Z4R4$k9YlC]:d%(O8cRe;cg_B\R*k@j?F@I?VX=IeY
	S.4[ROXf$[dal[jReAEQotI"PYUo-0lpZZI<Wskgb.&$GF7T!1%<BVft/;D>=FN6*7,eDq'WUlu
	:Zq[$"Q/B8in2Jfcp60jk=cE&mRNf!a&$MqH)"5B3aDW&?uhIct]TKN:'O3Pif$kQN$'gl#5'^6
	bPZ$Z1<8RX`C(-L0SMeXQ?!6#<%m)"GBdWNBZJVK-Oc,I$\+`.%ilK(T"NlWVd*CnFc-c*Y&R<_
	qTbJJmVnP1\i73rHApF$Ff4(Wr("3>k%qhZ[\B,1UccqjASWD!kIa^:C^30nUa=GiEfKQPnPe"7
	Dbf8^^MCArp"4DNU?0qbUs4*:\KYUF(P7Y$?ec/bYNSQOM7RNQfV_@ge54ni7pB3NT,Z&CT^FV)
	`:9YK+E31B.>\P3Y`gg08D/d3?)UB#[_/E?qJY)%="`"rEuqYa&hmNh;`PBdKjg5&HY+%rH\A!b
	@OY5`005&O=43jPYCX3Am)*k%T=-VrDPX?&M=,nnT7H_Tr&$AJZ!g>d4F,+tKo\&oiJ`P`04;8V
	?0hH=qg_Xh6N$5*P#f"W;2/?Y,Oi1AM,dCh?7i)qa8&)ub?r@\q<ne6?+EZM9d'IK]1pk_I$dHl
	dAk%B\1(88U;_"%L_%"*X`tNSSnj),uidRNkqO0kW3nV;VfM?:gIZ<\/7)rF8hF3!p2s<-mRfC(
	ceipNiI:dV;)c7,`fUe.L.EV2Ru_]N&Yr"e-+bi&Zl_)Cu*"euLS&d_17a0lQ]n9_i0>ogt"8M=
	Ecd)?D2LA!enVXEG\%<q2H6V&Pp]g'4%K1^S&^_g`&4@a0t:I</[DUlg;-(2*P=nDBRDCi/2DcG
	PJ=q+:3@GG:X&FU?OG6d=u*gV!r%0/g]"">&4,LJg06Z>*$"(oJ1L<;<>=.oh[$/>s*'V^4tb4>
	8qJNr4dZlA_O>cC78t^SBUV/[hWqk?Or8n]:JuN/e3_i*k+I`dKA/;/t,BFO[[1IIP_'hB28oV)
	@A3[Adm:V18VA2L0h_M)[^M&VjV@)YQ-5B9qWF:EiL+`kR(q:lp[-M<5d6*+t==.k<CCAb`lC](
	#V0>XN:T1hrgJ6"k.F:AJk$3hJn+lUs]%Hp?X!?"_'7W66<D8-'C?)DQ3K!9%phHAiJ"pbZ.1_r
	tl+HPOu6\"5UsYu@p56OocL`-N=e.$aC_Aq:%Vitt"7!(e3c?r:@08s_roYfW2OBWt`\P`rm1kU
	6gqEH3VX*b".\j<jjbA$?tLiBl.)0t03Be%DQgMKiTN#Ft>ONCTs[^qfDtdn)]Um^F`MCUu[KTI
	iXFVEBNNO^+qA5(g?1T5%+V[J<oP)qsN/MX+'I\FZ=rJKTn]b4B+?Ssa39Ih"M?9hFSZ7EW3,)o
	eHddk50Ae=sRe!t8[\1n:/*kW(a8./$Xd[a8@/Rd+m=O2UAA')elt\nl?Mp;E7QW00UP\^/Erdi
	e9GCSajd/U+1L[WC,8E8Du4`i7tm(</]7p49c3#:."gh'^\8.sP!O2+B@#.Ho)13i/slKK;d]5F
	-id&tFIdkD\R/,j3c:\m!pW\TC=tVeRf`laILZ"EmY`)?gHA"qSpJG!DWDWN?G$m(KRsL(-$WgG
	k?j_/Pr0+%hcTCuRQ)@Arr^I:_BIQ06XM?VkEHN!'=$ntZ\n_VjT"j#H2'C-u#ZfA^,1WG0[u+u
	Q^]P-S68[s8=rYm36K?C^biZ<[`R:Ks;,O,[Z>++kVV%rp]!pMo+24sOk`G:T3ApKq["XXf^p1i
	-dfhD1Pc_>YD%ZoaPZQVrM?[he`C":Oh8hYcF9H5oq*VV@4?;R26Vb/_F]:!6bn>\J<7N'"u0(N
	N`kK7X+4lGEbrnrC6%ih<6XAuV]'8'jF+n[="Nh4%V#+raa5A3OVE<*4*'lN"H8)9.*LH1`W/.d
	cMF;k.En>8dE(pn;0*^.s`cC%lZ)0L`JelQaPm5o:j8A9Z:48qYu;k[Rf0["@)mmj?Yo.t'Y,e0
	DH/MG-Sf_iiHiOMAF"<$ZOD?lX3.>mlrO6t#iE=(W2nK<,^bj^Pu!8L.(a=l`X5`s3`q13(qd@,
	i6XWh[#$ajZ7AG8!Zt1qcsjA#2&eNY935YbQQL)[`_a3R8Q:`bDunX2mmFPP7bo[aU^CeDimM86
	FA'H'/ifQ,a4dq!r2hHRkLJ<o&do8[JEsKPE5^WipGBXhCbfi#L[1A((NC4\sM4If>lG99W\Zh6
	t"q?FYS@pG4X;!^Hf8"S,09cX*LhkNQ.?7QRk^GtUOWk(@ZMg7,cEI_fJ57J;KZLL\?S*F/3_I[
	#1YoT$#F@3r"^7MPhF3X(`5epHLYh/?rfS^Vk<>;@p_PuIe""$D0[i6JZVOu>ltF/+QB^*Is4`V
	1E=]>(Y3EZp;s\LQpp(1K6K%X?9=pf2Z#a(-fJ96PCgg;RQpaL^ufHO@c8$^g%;7_o'R)ESoZm`
	W;KStB3KD=_F_-)RR`2N`FI*H#Z6FLeNTm20&Qmk@kMgo(\.$o6JWl0V^H7q?)h/_PbfCT$J^-u
	4`SjGnI^iJMFd1Mi>7D'Y=P&.^bH>[j/V;*3Z&g,q<iSHHe#MeDT.Rd5>f->-[>.q?dR^^;jPn]
	7k9[<&2Of]W/5@B/RA$h!-,VieC#;G$?DX[LDrf5[cC*b,Ta?,]=!SrnSV][Y'$.jIT^UT)UUHJ
	aT3F=U'K2r2d_d!`WHm-tOL$qH]%9neJk:_!up=K'M?"KPkj45.dG^E)VUrYr)k[-J/YXp1pWbB
	kLUZt8tc)i?DM?,:(0N]6LZ\m__1k]>'CUgEQ`ou*10?ULL=3mIAfYqD^X1;JfuK917eKaY^E@e
	$fFh6aT3f(ZG#CZ:n#<R`'mc,<&8'&RP:-'-mX5TFCI'!g0QEc$hB9Z7u%M,IIrbp;i7@>PH?Ou
	q`bH?R8//^4$Ef6)pm<4SIG(Uq%-O#XF;ZN,U^6e;^l+T?I/@\hc2ahH9Q.qOadda(b"o$o%3Jj
	tp-kAoZZmRcTkd:LhP3Ap5jm(@=`1.-)nD8\?`c6Jc5aMF,2\1p#>:,DQ,PjK'(<RKIHIi1[5Q#
	AROCtE`"[RZ%9a7m+I2^>$[HLoB3/*b.;.sn<p&,9A;M'Vf>B^slr<F.,E7Q4gs:s:pMhZFqlq'
	,ZslVq5%]dJV;;iRZ@8haJU@'Gt1.e/*mI(dRLL5o6AA+m3H<M?t^Y74V"3eU3;TktK4_\SZG3<
	S]'"L669?K]bCPN?!e8)AT`08T6N=LG7`c'[q5\T&H:S[!oWdQ^+/j+SP,220kUluZr`NYBIi+O
	f8Z\^kZPkK,2S0/3_E`u+k)eE&pq&l0RUer%B$h&J&,nN4W0,`W1AP3Yi!#a@i!!D("BY0od**I
	%fL*gKTNKd;uIIrcX<j0:lqmr/?KE/m5Gi!bZAJFJ#TXVJrp*JN[64AXm0*lc4>jjrR=jD1fHmk
	KHWjl8?$j#Q/T<_>'8D48"1.3l-^j$'I$*BMUhIO3LA\Uf]hAf-t(\FSQ+#bZ0r&kO(o?H#XQ>n
	&rtK(lZ6MgldmIpA7Tj=ZV8'[6H,`t<]YXR!Y^*=o&-XLTU9<0P\EnX"u0piB>o:)<BCEZ+l.D\
	-WZb2=ZmP,B<$"/cm0-*"MGiM3[93g@4ZKCNMu+.'&D:pIXn1?0O."Q9-[,\*LMeRtmA>&hrY>%
	TV).OaF<'/n\<aqJc<,a*K:WMt3'.hQ'3U<P<c%kcYuP0.`.)D&\E][gNC)uD*1SY"s]+T[>G`3
	4%1a;g`I;/9nuoK$d&'Z1C9Uesc)$8^h&R*OZu#mF*k8aXenk=H-Y(1G^dMcR6W9:JZ5@#ug/PA
	hR^3998;kuq:Y)sTLif!OZ.SB#a"9<pl&!KrMk<1]$*Y=qht%I/>-n[%4La+JNL$XDr^3o8TU!r
	8LOE'd%PCd29oERq.cXThKLGGqZm76STcY+,-Z/o?b#:R9DM[A6eGJt2^\m@9'[8$TeO;p]VG-1
	KfImaFaAc-3Hk[d)t2!]Fb;$G"jq5Ro^mEbd*m?Lf^(G-k"-kEf#qAW?FZYS<7G*9=0+j]=ZBR/
	[0%I;3Yc`@LUE8&5s<T+C0!8Ka"'eg.cZk5k8[)iq5UIp1,l[j+G>\P*MPGbL+WS`2NFhHe+E<^
	(,>1ot&"jR=j+1.P)&.[5'q':+MG/$!F!:Pi"AN[;4sI@@<&lp7(']=9teo,`=@HF9uKqAf4@in
	Jqjg.M4sYZa>j_UG!2k1YH2&3Dd0,`SGsJ#-hI,#Mt`EUaj^r[ZO+9h3(SSVF%eX#74f8T=/_dL
	0H7REjn2)!<msk[i=sh2X=(p.'f2e&)r8i`jZ;`O?&";HIYWVD&.1)+.gWO3PQW!t#?#N-$qn3j
	*Bg\t(\^WTH!a7FYc;@Bd=[2VLVSZ%E6^9G)m<F-Gm_:Hk#m;X-2&oI`Yo>sU-Xd;]oGe..3`=Q
	X`q;>_Opg_Cgl"$E(cesE^3HUd`WdJS!clC'%!!/-ZT:HMK!g=A*7^?gkD6&%g:OhkGGEVue)/P
	0u$6Pi[P/8f%JVDhB)5U8lPm^G[,q)KB[gRJq?3<$+G:%U1u#iiiMcS@[BY!t5?)>3I_65)FfKh
	84W2iH[.[l67s2pajfR9S`fQ>Dlp<J7%G+"%.CK^^[-E_0E!#e-et3pjNC>*]*fLp%h:[6*';O^
	@DMBWAT'Y9eqj`,mBl9l[^(]hYB6;8tJZSY^&&YP<o2p9CR?pAtZ\*c#\%'SHRA)*BY7q>_u0oN
	M]?=d;1I"k9_4&"qQ"Z2Xeo\[IRC9H8,(E-TYkpu<*'>=*FElJ*F7)G*,7%m4E\PnF]/!!40t't
	pb]HP.?1\!`qOrL(bK@kYo!:c%Ep9a/jAn6WA8H/\-PcFHBSALY&W_/c?1N:e2A.49NO9^(?h?$
	ZUAb\&T4G^1oHT#>a;CIH+g_`rb0dcepi#Qm!Ih8XkoXgs8L0Rb7lg2</<CUB4bP_IE0IB'!A,'
	kc35AIn[Z+RcY[FQl4c)d'6r9K2B50c7JW$EH[_`jTNeJi=E\Yl2m,n9gdm+49]e\I.eE?0s.Xn
	J^D\Qu9NLQ<:pOoa>U8BtrrF%EZYr[5(`d$?3(*A3pBnmn'BMalLlfO0@0O'G_0HQ(R!1533U/"
	\t*lVbC#>9B0bk2&Jfg$Sk%#W]^\aJhgEMn7G0pE'eBdlP.Q;7tF&P?ZUSm"hpW[]rsJojbg`$S
	^@pVf)/73$GWMV=)tKB9I"ZZnI@qbue^9CY)30aR9t#l/N,I[fo2'%QMH5Y%q#PCDf%Z5*,2om1
	J:o4?mS'X[6;@:lQ7A9:\(4,s+DSOKH&1A<q,KN-YnD(XUkf1Y"Z)pp$XHFXmO&qON?"IB";SiW
	P\V8+;eSN8We)r/Rf4B:ROIBNJ-[Y4ZQ90-J`HVma%`Y%'4UA+ll!q'-.,A6e2G0MX*!O;OFOhQ
	1j6Xn6t-/n^=Z,^,N?jtA,q+"QAeSiROIhl*S\^M+8.q^4+qplED=4HXCL_59X5@dbR]R1D7X#&
	rBg3<QHJX.tuMpf7=b)pNb*`P#X<rO&GFeoib#2<7m1/oEU=ZDe'SWe%O9*k<!mMfrnWA?M'?ko
	UQ,[Au_T\q,[$,-,F@._7D)?19bJ?ikBJR-lIp9h"9[neFYHfsP\e$c8JQFM,BY(8Is>2j59CJQ
	RPU[0G#%alf;sGGoV`:IrGKeQQtCb2pq_r,S)?,(2[NBXMW3K;#rAc2/tEb*'7:E>UY?lfh=f3p
	Q>e<Sp6Ei8-3`JZ<)PWm\b0-IjtV@=*j6)9W:q//RGF7oF>W7MKLfor_CK&]lCL4^","j0m>m4)
	&6riO$'m\Mf.CDS*F),A>,(VnFqAkX1559aQ7p_g?N>\mD!cqM"6kTo'ZqXWt%Q"9Xh>kFM\!C9
	;&j`Q[)B4_);M$2ddL]4udDB$s=!kk*V(ZV%G!4-/2#%_V[cf/0PIkm^CTctcbpeMJjeeg]*OUt
	TQ1aQ'Xs1)U=;K]J`#j$(uBPMPL6&#R>sf]ru_-+D;[;Hn/k)chkBNXf/%6W_M?mRJh?1Q%[\m\
	t.<H_tX8c8OBo07d$XTg7_M,EOY#-FDo>/PN]]mm8Oc#0ll:[-]nCQ(<,IRFtu95WI'?4H0">[l
	C>L963N+p,^^OCj\*KD$.acEq$BW$urAkmJtE8,:$p!&,=NoHVu3G1cnn^G>q)=:G?)[O3O1f!S
	_N7n<Q&[bX'&5N)gRMFjShtSsks-6*0iZaBVMj'Ll)R,l9,i$"f8X$Gn?&6Zsi[3guGUDa\:#'r
	rjG"F,)a3p'Y=%jdd]OO?"dg)tKuW;sq_3R0nQN-D2Ff$$-Qk]%XGpdai>;756=7(AUR$ps'Z=[
	ZL1$g"fm)r%i<)S&kI(TB-c:.msSnG`L(*BqWdaHG]Y9$8_X0A;LWk"hAciu`dR35n:d[`aX5Of
	,5j"oKh=o,/2!1n;]?K/Ap4TTQe,l-hW-p?b7rV-.O4!":7Akso6Udlo*bkk`eT/Zt:MV8CtU[!
	&n9bA="1h_>sgE.2;LP"'4g8hN6Ngs&f]I&U4[Z[&>'CQdIfrZdZ]`JplKfIN)JZQT4o`d@?TPa
	$#%rZk'(b4:nW)K!:@X_#,mY&1SG@MhY(aA`6a]0lY7oGin`Ro+?lZ5QJ1nTSIdnEoY-T_VG!Zb
	!f?>"PWW@hD5$i,d!\G*AGfQ%%.6=6PJ6E`'9iSCt@?Sr9W(gWO$*6%-9G>TjXOW>OY-U4PoU'#
	dU#gGOBO*iYnn:7PUYB3A\#/Lscs5,0t+>sO(GQQ6!8drGMK+92mQ^Xj3iPiT!UmV&@$]00?]F1
	s1"]<#\09;ZF79ob3DE%WM<7W`'u_rbE'dS;J+E(sSN`a87RR7ai]GbgJJ>0!]/QhhH"V0@1pOG
	D%8?b,#nN_btS7Sd=janDh^ifeB;Pbd#2f[K@#]qsT1j]DY!mHtFpDdA5%XpQB9!#EZ]^.*EL.7
	nDo.44D<4>is!KfeU`gS.#dBp\4_q/1XXVBa7s$T8_c+!;S+<`LVVgd^qpp=V*Tr'[!=p7\5hBd
	\):M@$JmM)Hdk;0h+d39f1fRYXGT8@cnBl7uhT]"ZU1>2JZ=KUVIG/`;]QgU]lG+0K[V'_Ed*<U
	I&_X^.98qe.fZC"hDDM.j(20H6HLA/gnGS]$[P&o`84l8-f[9g7Dqr=7QX$$>K/2WF!h?k+&@/4
	bfWK*-agS<,dhj\<Fr3\6TZ+HfM,Y.`gh5>rKHMC#^"4%No__.<U`iBiP):oZ>$SYOcC:edc<M0
	!Ai*R5nH?PTBf+c=lOPK]IWq5t@d\U_3B&=e>Bcah?V%-+I,.Q5fo`jPGK4<8JbMslr(<JpNKO&
	Q]X\"Q>0Ao5eSIdbEGE-UQZ&s"Nk@\Z,"WL'Aq]&gZ*Y@uXUWH"tC#UO6ljT%e&gC+/AE&e=s?D
	-nIdD]eIrr@d0kA@TYR[RqO29[u4NJnd0_FYs,Ropd6$K,AVVn"c+O%%=uEEYfR9'Ou_U7Ia_6#
	5Fi`SC/')H;\-!>PdX?#u.AY]q#GpWjRtQJ7VkDm8HtbAC.oiptc'>;/0l42rsE:^.FpLV54kfo
	F1TUB=QEll,"HT$ln:JPPiD&=i71*1V03n]sgO^4b/a$L.q+].lVt3b@/tHQUN+FsT[k"F\^D+,
	Hh(04nVi1Y")G4=tSah`KOa[buG'FFZk'Li:L;ar7(7@8f[;8pRf"8ZjYm?):>d2c2@8O:k;-N:
	6i-g8C&b`p173Bf$?tBo?hP-+$^K4&2n4!QII+W>m"LS:2<QUY&c;-?MHZ[I"pLf(%X$>>(u2QT
	)ALCUeF!7Z;:+O'TR&6+;mPi8[[>g6S3G^)$LQig82C7BL>AG>8$sVVO]&@6uIN6:A_O(G@!5%L
	=';'pFNd?=uTBf0#DZT9"+X;U4:H0D'*J$S/Tr9:rT(:lAmoX<22I3H,5G#WOg-C*cn2@qa8V;^
	:9$!0)))Y7#)gn8H"lTm<4[)`%#b7D+$$7:O<'^ep%(o*cOWW1JU+-?n>`rZLu77FQ)cmra%6_b
	ZHP17BIca`HU+UnkWJkfD\])>)jUhDGqq_Gm!@^n7tEKg4NMe?<\1qqLL?Zk,R5b;<*d<Cp\>h_
	"oK<<22-P?5o,.n/Z4k34ec*DJ\Dj3NQ=^Dm\ZR'(h94G:1gK',5s*/!B[9-)fL3R7c<@u$rGnt
	(7!Q(qCFeiQ(urm:LILOuZd4]b4f\@fGAdA"(\=]Nc&!$/m!H=m5MHHG+cVeEDZR)Tj9W^g*5rr
	<K*AY\R@&+oad/f.3N;O19a-b.#YZ+3c7PDo*u".TtBEn5o;;9,s!LT;?#Ph)0^%hiUp0#+5U,k
	g\H&kT<6>.e]3q/Qh4N^1W)S0*("1239lN+@u/eijRMUsKKV&>dTPENtDXpoG*]*.JPtleeu,\e
	S5q*:Al"F-h@dB%*D'FfJ!XJ(;XKL5>dF&uWK>R&X.H[O'DagnSe!DOQNmXgN%_D4Y[Q/8'CHIE
	Dk[B`eg'J^`jQiG0.8%glV-g-)NY?ejCaXeRX.G/?7K;M;8dh3:,Qalk3[p+9Ki-cOdYgM&Q,j3
	&IjJ`>-iSlRD>#+&gX>PPM?JETe\1h_\kS]1TCVeB+*Ut[Ve8@7ur&WcA11,HCjP1_5QlmQ$>B+
	(S]&&LOGQIf9kZrFQ!:1Yk:Oq?&$)3H"T_Z8b-4<E8b*Mg).Y8;;,U0]<5T4Jebo>r86nj^Ot^G
	Gf#+1[I>j!UIG<pF<CqAu]sX]Ej\%,4%OLd'@p8I5MJ_M7*_&nF!M\A57a>at(sV2m=Y;89Gi73
	T5t'($iI#rs6ZYQ0%?<I9bMouS=N(JbVNEZ[lXhjqRbgdr:/gZCSfPP"0DXh@FIZZ!,0hBIjJn%
	m]][!-:(g>C,a61]N\^j#8CB@a249NJN#bhZ%_:[kcke?:M@b1[e>aRXHK7K=IN4&,e:kG;5&;K
	mF/+9'X%'fB>=lI3R\(!J]qJi/S@W=iGI7agPe]7@SU\ZT(8;Ke)@<,&l./^+CKVsjnJ[X(-<GA
	ST7):THs,]B0QH'3Li.KDUGn^ap;RGF>kb,gPO)#2i^nPO561VmrP0LZX7Ei9MJ)9G"G-a;io<Q
	6GT8Ai!d/oBO+TXTgH6H-^eAk1bLjPX[5JY&L9=s]FcY3jflr=TDRZPc.DE.UEL(\JUaHhQ\md&
	_>XA);I%d;1D0T)EcSF+8H+6s:O3;7F.(3Q_ksS\KC^!gB/.e4f*()/)-XX&rQOIho389D6Qp3,
	M[sD$iH88B"2umJ%cGG,ZI?@IKj.rYtW<UNj\pG@h:2g)DPVi\1!7;5AbD7UZus"CTD#%!J=066
	D[E24U+-kd\Y!m^*c!]G;;%DO#^L>?U46-DrsZ*/)AAjAod9-#o(JjFQQQi1"b23mpYgaDZ2O4^
	NB@X\q/RR>'Nndl4U-/d=8U4(K>&T6hHlbuLm?(@'tckgt8=dfu^kIJ+[-8b3'\k.Sn\+@_N3+:
	R=>8L#U5!#2WZm1?`^]-p%L7;!7NA#<HI;]tm:lQ?Y"8BD+*Y#b951.UUFWSu4U%'#IqS,s<cO?
	Mp4k;,O988DCGXgE:r'7HF3rrBArfMDh/39eaKVkY$+ke&3"R;\d)c$t*$=rB7h%G3`t<:sSqNe
	=67MTr&I$VaaTdCq!##K#&U`BF3i(rRtfOQq*QH0fj0aSJeRjr0MG:sjEt%i&diC)/RMf!>ED@>
	7Yi$B`tn_5pg[G%KJa\(YP0>Kbt)!"B6no.=0>]Y9P2B9:-ugOUGnl(3,a9%l&/Uc@0#Ih_ecYj
	j%+[h#Z6"m4:A/oA'E:Md0npVq!O24nBE<*&1LGjk?=nL'*6]0/YS]!p5_d5d\E^R>Nu6,GPO[?
	n<]4HOX<]rYQ$W_]BM?$=-*rZ&UW;Z"?J-Vfg:4jK4,=mY3</\+CU^?@-&M$/"D!7]j<dcK1Ro8
	ada:(Ioj9s48&KXOr3cLq[_A;qfAR?/49=!n/Ujr=tpGSTr=%paOPIZ`Utn*M'@4Yl_:1K3&j=k
	p*U#(h!>aDo;I69G(kOKYdGh1+Gir$E?"Ir"8kiQi/CQI:1k:RfLaBbeE:12Ui^?bB3e8qK*d<1
	oP>fHjD:qtp+6ep\Kd_AR9iCXIC]8\!3HQlBa%R7u[o\A-_M8bCtr#f.ArWKc2'X>L.dFO-Yf]D
	HAn!NhuIY&1)Lg#l[JgTB#-ZDJW#[^O[mR-q`sX?Zjl\ZYD#eR`S.4F`95UAk5\IO3ERK3>Rj10
	\KOfAPH=19LpscN/20_/[bF#;k>%-#]eF9b6:XWT-PA>q8;4^%RM%M>OibJ@?36\=Ko0/b9qr#D
	F6QaoJAXccid2dF@L^!44)XiB)HH:@WO_A+:O;:$#$Nh7P7[M!V0ug&\[/A[77RE&1OmB;UD]Jn
	nXdrr<pMn*o(#RoS(J>DV[8<g$Op[L0:Z:=R4eQ:VWuF7PouW349cH*i^Q;O9#@0-+j*5JpP\es
	#oKhE&$l!X<.7qml>EP"p?2h8MuX^5"@+.^FDkNj!9.ZF'KD/]n&2GWj&:^,aM8C9=j:L==YaF/
	VY?MnU&1gpB<iB#ra4?9^1L44IJ5:2LJQpI(#^>3>h?jgI*+W[?'KB+3&"4`c?&)=0H3/*\oXnE
	9]p(\"Yl.46MSg2?J^!k&C_,E@D8B=B^gOtC!8a3\,mdl]SY<lNP)RQT;aV][a%CR:[)"j^19.E
	\V8J?+Y'5+HYPWdJ_[a(/A*pK,SceWX4hXDTnf&aBn(_A-3jCh46bQ@5Jb5g$^\g+ef7A=O',:,
	..##+JlH2'qbsL#IquDlNa:C23K_M&E\rXpC'@@fn!,WYdAH#oQWeB<=dZkH&KdE-$[hQ.b?/*u
	D=\&bsYg/<(TA//Ba\_T:c@%3oDHH-c6mkk7l4?WM7FBhCs5LYR8B4u)RBq7B2T:PB5GZ$?\3$C
	JmOa9+Y*hNEXDZJ9>Fc*hm6a%m@_2S'X2`h@Z(R>P:ip'<e#Lbf)'!&kWQ,CjaO)RfqD6q3o/ZT
	UrRnJUkhL9sUU)Au^:HYZa7jrgL&llRq,k.p&.80&#]9pIje`nRJo;:G<7'E8%=T@nqbO@,htrO
	V51.O;@)FH!Hl<C:V%^uY&\B,>gLgZW>tmooT*<j:C^kaJU?EI->me<<INW^iA:2K09DkCj&5k5
	]@/g8d_Tp_'&fZ^3`@UT!E`.@3M>gG8tP=^*VIA<Su7S<dVg5Bq&J,9s*DI#0\U7m"'=2g'Tgpm
	8jdIYFHi9d9+VW9"ZWCROlOa.*gVM!*l?:2hljB?M<,/Id!dXVg>(nJCR/IqPZ_C)VM^\$T:=&%
	4[Trr@ESq5Vhm0t5=NVDFF"`=\pWZoM-Yfg\.!`(2a+G=aitj58[uaaWV&,fI\V^/So'a>,Ym4"
	^b:>?P.Wd260Go$k/.mh3YWLaBR@T(4mB!6K4%<=.GH/A:u^5.uq(.k;>nGB4!d^4XDoch==ce1
	K3p]Se4>q0d8L3e!@@P);8(Pb+Z;4E5S=`uVmPH`?6F`!0oBhg<Xp"7mrENd>3=8s]h,=(YX8..
	*]TM6/TNZ<Z_ig6[UJ)^I^+cAERji;P^\;hJi4Z85K@?0-7SgCK6he_[>JQ)A>9g@!at!X)HmPF
	^m":,5Rn[@>(Q/nW?D->m(f*Ib9Rf^udKX-M0$+:b@_^PWlhBo`7[@L4/836",V24Q)Of4L5KbB
	B#nGZS,=jleCCNmc*IefeY8NnW(.7T)+c$qU@U4*"DR^]]g8k=VLuj3uN''rfs^MdJfaL8gq_2p
	kp`?esr"K1r1?\<;>![]&1?*2'Ur:I%uEcUs$mP2B2/eW/r\d(UT+gVF?mVUr[6Y6Dk,q,&A0!$
	E%,:>e\(*X;cL]dG6ee8>3c"DTZsEkhMS]+ZsbEG?9#SX%EBdEFQ*mdgfB%k8kEE>33+@7EgcNq
	LT^UpOh%p9Aq_S0a66SRVU!?T4.mUta]JQ=u0!1#",eU.:#-1,)L&_>NUj:JHeC)nfCfWVCt]3`
	_A[rL7>?$VP'jjmF:L3F.Y:)k/<4EK3QkTf%%BbA1lV%YmUM/U-2)'/$7@&:';",Z^D*e1O:"c*
	S^.ODoN'M,et]NA\Dk4sXpq)J4pQe*a)SG%J+nPa-E(g2e+Jr1bl.@GBD9CIXlP]Ob9KU[F^R-1
	07?J8LrT1<Lj'LI_nCZ=VRC*,[kk7W:%3YEmXM,+Ff/PMiVQa()5CW"UDp@l3oc&W'm]!Cd+Qju
	N&6;Q-.ggo>3trJDLN\(U[r%/H!H^M&`2mG:UW%JBV94aAo[=%"K?Q`fa%9kn9>G_RHQ>^XG,=:
	^nN:nk$$DWCC/#.TK$`iCP#b:)R0%q!A\]a69GGC-*9eU0uT@bG:Tl:G.VZnS8`f#c#afDn-0eY
	Qhu2`nW.1JI>HNRc7aD5GSI`4f0O-+:Dd`^'"Bj4NN/XjhgJm`=efX,D75?tPI.a:X"30aE<.4D
	,Zpm8DWKe?O5Ve8&FpYtA.eKLS.9kFi.\!7aD['3ZGMi=CU1Q\>%V@Q:8AkuSK[f&3&[(1MHs4F
	Eg2c(#c7HJ838T$?kP*Nf<qQ>f-4F`@LG-lHT4J=4G*S7@W2Zb=UgCgu8S7k>#fQDXXA<E_Iij(
	g=lM,cb#*$1S<4nTU@+RflIV0k/MD<KKPDGp"7Bs&hJP6J:uTAHdpQB;$V<+$,uT9d!f<4BAtqD
	>q@2K^+q%a90HCHX2cp/bQ=).2c5eG6Qi0&5IjM[7k_NT=WS!<s!Qb'/&neEg/_<a-XapoaJN5h
	!KS;=8>79mOJ5<Yl$<^uA$V)CaV6bXjqXMuX)4pNIXZXEL3H[AVE9_YQria).R8bhC(=28$([h^
	Jo8@s)88MQ23E"I&fE9(mH\D.BC:L#Yr0pmu=df##I(dFS,"&Zjb^EH?1Eb(e]7!h0E?&DV+SOc
	&!K].fDtoA+&r3krQ!C@6!Lpk>ni+:0(e]TB,a3H2*SAdsGiR.*CMN:U7&au[M03(A3c)#B<4J*
	jpf8"[_#GF$JUM%/!cA.g;%-S!$!aQEfABWJV;0mIrFNK#1B]N1UA]$o8*\r.4.+pCu3Q]QGjo&
	OZT>u\'_Mq%?<(b1`/UM$Ru-g]*[>C8j.a7_u/f?Df7\9Skp!m)Am12q;ef=@iZ<E*jOTsc"pUB
	OCu=nKaelnhKK0!d5)L!BUf@cR2:k7U@L4LQdUH@tet+-c<:cSW2/DWcBe@t)HkGH:LVo1=ti0(
	f;tOqRk3;Z9@8_\HXR2@h&GfE?51*a,CaD9W9d:5JY5*7@Jl]#)8s.(.96]>2SL(s8B=S/sDB*L
	#?th01uj`Vp:UdQBU$Y,7Zk%kZ"G4ephY%18<+N%t:lKJ=W9!CpX(.Ge=,%Mk&L6c<$16`Ma*`)
	i%+U(qq+*EC!e).-m:0u2SbRb]Tp`P$(beE4"*7@ojCc6A;*rr*'!p-R$c\<3OaHEm&2J_$fsD9
	0=_h7M#I=4HmNgW#3+>(Dq.D'(!erTW-si.;.oEc[\=C-1X$\n?aLX^H`9N2W8c$s8K6i:$g.,E
	p_B.6euLRO<]gFA$u8]6;l-l:!6IqcfEa/\XL(W2GjR\^#M3S7]*EhW=C7A)],Pg<?;A>fR`8B+
	Z55"+YX`J5>9!.`cO0WO)*k8?mXUl*dgoqCS?QZrkE%K-20--YWEmB6>.."M([=pm^8=m'r=g#;
	(/#C@PF\Mt`1F+=O.+""`+g0G%4'bAEA92l#YX^*qR64;Hi2-s\ZFG-G4dIpeRB=m%jS&?:!u.L
	pc;2,6_L9o2<]aWDApoAU"5r,JIs3f^+f&Dn[k5>Ta8%;cp`8Osu,<$=]u`JOFm'WQ5r/r*\?b8
	^+6?\I"AT!9Qmd(qlbS"l//>Ulr2)i0a>K&8IX$?lnkNjU_qT;eYKZsN9.[tiE.m`nt<p"+fF7g
	n#mZG>(.jKg+>(1cT[a)UF*J5fLMI>F(k(q-"BetTRZeMRdF7?jL@\$ip))dYJZg^pu=7;ep[GU
	&eK2^Gti/^D@Cg&D&jGFoDDnS;mR&UPHg)Cp_9f-":R:kB?*TI^,\k9h5ZPXSmA'#)Bjh?!.(Y+
	@;AdN30mfVVauL-uIM!-(aQ+c6121WQn;Yngs-O+TPhAZ!^d!nuCD3em+1[+!%@"DBQ`N"WW_j:
	HS=hP&PS(Aa>r8k3CM^P80]KU7!Qf1iGCE89`iD"?=+?q,?0WPDt%*1+YM!-=?WYq\l5Z(g!XYn
	T6#L:!A.XjO`.+cVBsj`tAZ36JUu#39cbi[4u[S^+9Bmd/aX/^?T$^C\%"AsW-o's_W+pGX2J)N
	^+@[YN*Qi\1R!h5c*n?+DQ)%$FP_>ELqgbYtK:RI\BccSa%)=1>MA9`e%%DfX#>=l)X_kR_-_S>
	[`TgDlD_C76ktln=0BF0,/O9nahofd"^!YsFM[8'?T[i<LTh!%0mA-A<;TD7Ll`aEXaO[>r\d_H
	0/FR*E&tgeU$EqU'EX1YDZ+[B[-':PB\Go%?-uaP?LIO*\F"E#q6k0($'7N0).*&3Qq!$c7IVUX
	0P;9e\Tp#JoqT\d>KIe4$e-4NV$D#KqK+18G>Xl-DM-\Z@;dk$bUG1^uq6-\u&27N2u]9>e8M!6
	#JlcPSV_U79[74TjY%`OU*TNgG*)#*bgX1>56jZSONdq9IDaCu_uB`c@,!WCbb:b:Dea$[Cfc7%
	O]$E_.2S<Z[okkA&"p;Q])D%$PtU7XNO&Qku>7L)J4OGo[1X<2;#][galQ/<!\R7_q35@]oG?N8
	*/`dMW0HYjGo9'pS[Wr@+E[09&.!GXKJ37\O6#SSN!3-n-\Z/99Ld3>*J;LA1.29rE(p-EPOaBD
	;W`_p)%de\$h=2X+RsdV309)H+C]gE@m'DrW-g-R0HceJbEWntt!X8&sM=H9>LJe$ZN[CDWQeZr
	jH+[tGqoWc'j%G$>"l6F-cW(N'Hd+$+;]PKD@Ma;7/4%>5KNGiBT_RlaV^Z%Go-UK52KLe+:)=;
	W#q,7DqaQXRm7go$fm5eHNg]04KpDY1P/<tQH5M*T*G0d)(gSfI@fku?Z2Z6;r?G'1"JOlNKF@+
	@+<]CVD>V;4W`SFM25DNb;I0g&k(W$'Y$/So=#T&PQ\LSS0hl7E1aN1[V*&5&ehaCaCnNd/Co#m
	:?hekKH*eN7GdSeCh35D_4t/Iu1:FPdX%b*KL4NW#nLHO>sf)\lp>YOLJS@Eof6/QJ(QmA&EJrO
	'".#l#K:d,i`2`O-I_,OE;D.3sa4[Z/hu?>uRr`rKN.SCGa=Q,5#ln4dQ94t>,?BWSRh69Cut2k
	DI?9cn+=(u'_0*;k\f^`c2c!,_oXg),[e6OK2_:#Dr%Hoo'o[4d9cHA0nKSSkS=@Rqg&((c1I5'
	o3f!10Y+($`eYWFiV%3RXHKVR3n_>&3?ujb,BPZ:,`A,5Hj,Oh-,.ZnGA0T1ZgdAnTHY,4_PD.%
	)Z(DPMd\`J.$>"RHsNO?*Jq%Sn*>B-k^'F@#LS;o9N=Vh0:L3XnICf$]C"Z>@X,EH<bgW@Xm+dL
	!bD1#&Q]>ja4>m-7JG<]Z-\*bbC/JLn2ZdiPcm.rC:S[#@@j50`Fl/[u.<Slh/o0u2%(,b2=sSh
	Z8W2)UGP*[1&R[[Em9T@d"M,BG'-No^QJO]EdD%*ZKeJ2%:l#&,Q+NTIZBUo!MGES`(nmd<23W]
	Q]+T,pC0i_o=uGm\VUF-$o=1Rd/]73lrt<neEUdT*qoV^'0F%"f%1$Brh_@->!kWBYN^06nei6A
	nVIl8RrQ;,+3.$Ogd&0-jE_cb;?$1$f'bD`#'NG5]GXZfTMn2KO-:3,L6)(p+p<Gc.*jIJB%sTH
	g/Olg/DhXXnK]h;%ioi.M_VT+:Lok)qfA2R#6+b$s7_Gm_J$i"P[5!#PqYpT@]%:0K:qVNPnY^8
	GDuD(`k.dC&EW>a\4A:$0LY8%NCZNHU!XV_>fFp_B<gMbm[g@ZsP_WJuCIGGt:0?i)q`RaTpXHY
	/`*]VJ)m$5p(Y/bA$)E_0ctW]'!@+lAR;ipFBKV"dR)>nS$6HBaN!e>[E%kq_[']7T^90ECBY8b
	Y*;:/9jsP-GgRY3]tP#pnrX9fl7d]=iat53A4W]C4'BV2-2I&$82o;R]%tEDaJl#>!>bTWjS)Mo
	\GX8S(<mCB-Y<LN24kI^O&Va\ut`qIZ8Fl]u?P1"],#,Hq]/XA2R*!ql5[UsRV[AA8^_3Ad*pE?
	!4dE,F:<jM(+DoEp'Z4_g.,'&#@8>qXAqJSm-,=.$q37a;=$ld,])mEa-Z,YM\!INC9#3a5kF"P
	Bal&q/OV_u+q-X\uU):K*q!dC"m*'dDeqar%Ljgo/<8og1E(9S(XsKd8#McBCWC2-gE%$g+l(2"
	A4t`u:?+"b@$>M)Y_f/Qp528YX]SCs?,TL@G_A_JV3_c%E@Y1>S@!,$aI<L3F[palkf_VonYs9V
	CIS[[q,+iU;PJ-&.lBSa3qH1c\JjR$!`$:oTtHGrXhHIMp;0goV4L7\;9oWCOgK>'rB3_5?HTVX
	!djhY>09gVfbTNjq()N+3'_=Lgqj:L\$07U33&RiXeWlJkH<XO[InDrjHo!Wc7(7eo%rgF&M(4m
	FIK7VPmuEI+.IL9F_Sb1B7iOs>:=dTjK'E?2X1#S-%%b7&C4?Y\l*V*B<Fbi,Gf;UF=l'(FdGnH
	r+tTIqfCYn5#:q2Ebk9+Xhu(d1"eVJ/LSFKX3(.WUu[AM#HURPq!ZU?WOg7&KB\')@ZLchBsI;o
	4\7i/VRZ_jOcnK_ZML\,)%I([uk%bAm6X9'Tht4lMH8On"/54";m*;GUKTN*T&E/Jc+QWS]]cFP
	YfW6cerdH0*C0]7sS6/BlM>=WB=hj6/[(\(@6eoMrHU4Qh/]bSqKi]C9pd6BjrR@Z5;iA9K=;qK
	)+*/L@'`X:!esKjjJkLaL7@@j,_M)]D&=!]tep7t(]V9hW#c(J`A2T2VB2D>*8$]#GI_1l*h,Y0
	GG!pJ#@31s=Jdbr,@(.06.n[#CR_rr<rQeg]JM2K.sBZdC&2S\@Uc.s50KPOg^rn,WCP2g4PI,@
	mt'!jTD(?Pi$[ioT(>^6TU9GRAta805>1kQ%LJa0EVKf@I0NLKN!C5'mSEMut^*&+_2!%Rrg)7g
	/#'Vd5'hCUAD#LG[gO6?.J*OkBI8Z%C13M\7qH5K#SCHA[%A@:Zf9Q-[B,nD3d8HAS4A/LOm`G*
	,p:NJh5+*AF;KS)m5M29b/mEI)9<Qu6*]*DaTh(-8%^G9s%GA[Et7jR_q)Z6HI#S1`>E%Sq(Ln?
	$o6djd7Z*V/IHRa.XgDd`e?>RrGd]U2*1W%>tt"<FPg3fNZfkiRcP_i`,P4&GHQT7j>SND=h1F*
	D=T&6^#p1IZKRV3qkr3ST_-DEoe*UG^4mZ?es1'^/]V8GSHUnSP2B:Cp`EEnEt^Z`MAY8KtZi;T
	ombX?^:Y3#e3%E&koE(ugaejNc;XU5eVt?O_BSUc+:1GTT?'DY1Up,%cWl8M$(J$'DZJ#>?a)`W
	eSASi%0uaP'I+8=i7ii@B=#?a]/;mYi'-o$+P.:%j`9_;-0]N%i6hL2gKX:SH*M*T[&^cu`Pkl?
	iIeQVrMgX<kH8iYu$f0J)b(?./pmT\@"L_8u\7cL+mTfe#akpcGNk2qitbfCW"@gGF8!hm`D[P2
	d#5,f'[M3G%.,N!%M9KX<P*;_Rp/*E0iOA?QcB("SXY*(&X\m+>g68\bq;]9Sk/h8H=Y4EH+P28
	.58BkU[^LZ2TIBU:b"l)JJ076EV[Rt!>nQI*52=_1ZT@rQae4+R.3aNfZ7kfhb-URCn<nD;X19a
	X0rH"S[(\kP1c8M8^1a-a+qmActC^;G.;E[[/NeH0T$cI;K&na2s$bDC/niGEnb6M"FW/C$bOaN
	9TFJI2p],FWRC-:I:U5-WKmW@^4QXB`qp(0N8Qj^O0V`YFmXEB^:G(d50#"$0$NjtTnsUYj'mh[
	[:ZF!dT-C=Zr77(HbP7=YHF0k8[Pq0.#b3Q;LY.I(7rL5+iOnWkg9krK<LiXIs6f%X%K`noRhg.
	U#0N9-drOu3ZMaW#M8^uQKd&lI7ZU-."1*Hf*&iZAm"Q@IW&$bl,fL7p?H4jLe^;$KKjg5-b'#f
	3t1[ihnPP?Fe&?7]qb]/4hGYMi\m'&+b*W*;hE%-U)I1?>SmQL6a0]feeNQS,8'eb!L8?@4@"45
	t/i,VJJ0GAS8U,_l#$$MdRK%Z#R'A7n9?7W?.RN.Ib'/uF*C4Uu,ESf$r-L$*a,];\;2*]K\imo
	'Mck%P;AbK$!M5UCFN-NFb0X^WT_7(bS:(@F:VT]qoX[ME'A]pdq-]njcU"YK,*$RDp_SYui;]/
	M!D=.WL&>I"&ECifRgdsON_l-$86l?Yq'U=n?q2"Sa1[3@IZ%nt!c1Rs3qZ's:u`L/bb6k]8r`t
	t1r:MZ]a'H<cf)b[T+E,_QTE]FAuiiAM$W4=1b&GQo,pp]be?^"IZ8^m,"#jb1?hQ-q;RU8:*Ub
	OK(].0ggr4U2S-Fr4rg.Pf=F(iN<hT(U]l.Y$UFFP&lWTlE'/WKJ4QhIO<U$br@i@7_^;t;j.6E
	S6uaNc:s[C8e5f[cTXKt`m9pVqhanI;&gY9H^#9kO'a!t=`Vch:It78h/F$P3\ROc0]fCR^a$X#
	@7V6d2^?X^=r?NqZJY>L,#Ne#][GP`'4EE"[qf2c9.)BBTg/?.VD[h"M*P6Z"K2lnhp7ZdSM^/X
	'E'\g/pYh:r+<5c"J8)K3^B7m<gqS_j*Qg/uY0eht,AlmC0Y4lP30imdCc;:]Sn8a`M3#b?l08b
	2ehfL?4.q)%p,[?D>saVbmY(6;AEV#K!9`dq]FFFm(A=[I%tMAHVZ]]XPD:aj.*B,jqK:46"fQJ
	8a6nTThs/Iq&(d]Uf<.HUA,%Z`.pTCmY@i-`YVS,dW&@>^!je_:b%<lTlJi`YoS9>+D)^&HU5mo
	/Td>f-o8Q8+^5@r_j&Y2[LiN-\m\Mf-UUP"P)00-&d5g3g0ATqb,Vh"dZ:=_0['%C>fqU^lIL`^
	`pH>]]#h8\LbUD\VQl7j!%!<L1YN9U>Mo)$,nIR!qH`"L>%h!oPfrO.."Dq:!$qipNm`GkOjH4U
	nds?Wd<EZb3\eBqa3JP!&%Og^0bYN:'a!UB:p"%VhuN-[=rcbr!-$/or'JdHqkL:=g[>FEgnMf2
	q/O-tNYF7WJjE8s?UjS\5Okdj[2cHC-+WWQk?6eXKOiAr\g5l8=e_;TU!/4D^^ES;dC$Ob&H'f!
	U6i`(5gFmZhRfC=9N>YsF^YOfhf?%L,620MYA.*R6I[.GhlWWMAJa'MY@gZW]16I'>?s']AT0*)
	nL$mXDc3YpPe!BDq2%JZomRSd?Z`oW;/kDaU,J]LLMa?luoq*bfaYG*N:mq9LENFfM\o5AT93oT
	(Wub1O[ZTT:gt0OR?['X%`]A5hSke1N>^MmQR;mB5WVq]pLoQ?hY&bib\TWIUb&!f`.Y7_Jf"ib
	oBQ)ZKe<]J.0ITNp6ib8o"A[6\jV4;8,:JD&"]5+[[t^8'g`U$/,Sc\WS;9@rRDilMo)9W>e(j^
	:VXdj7IZF&>eJXuO/9^576u`c7UCc!s^8gS:ngArt6k]d6dOW]`gAHD!:SB>]49[s7%8_i]NbA7
	D!N&Q7(H(3<kORs;aOT6dPhG4/&1\[U<=.jobH1P>!a/ok8\n6A.)nBJq:WiUn4YAAVM.Gn?\nQ
	3`fKq:'N]HnBfi]a%OM'T24`P0=H*2pm*EhFf\-j4'n4IYVr<8ON0l+:VViFN-n06I`C_Sm(FKi
	]-DgEYI]60juiY,3Z6A#%F)I`Z^6lq'\9*^-/#?8=_pc'p#akh[B.?cLYu6KBH,WGYCLh'-@R_>
	.("G77k#8K$u!92/9`]@$%c*]DC5r'016]1B'bJf13o,FJK2F9D*U\8fE!gRiI\ae67>l[I`hpr
	C:7rr?p#\p`lI(@.p`N?+S^5u_91'*2ZL%N1#h%j6JS.1NV;LZ(Fk/oOo$C[H=4KZ,q#@$*&(Zr
	SGio%C=m#Tsg4V]Bio;SCOJ/[[L+j5&:MCF=l/b:>gDGgP1jHCPSj4/k5Y10D>(4,^?=Z5^>2e>
	L!rW,6$Z58ncj^m]_(p6R'Mq\)bFVqSaImtkWX20Dg/JPnjU$Z4#>CU06RQ+0IdO#F]_T$r^ZoK
	BNHnJiINJh/RI8\EN+os;ak(HI@GFl!1Z]uf!]p,mZQB/_]:3;FOI(1H"nU(8/WZ.lDQ&LEdb/Z
	m"q>I2q\#DP2ulUo!7dQ@W.6_N,s[kUuhl=O`L:n=e,I*5NH8PCW,Gn/EdEQQOI0Uh.83[!g%6)
	8ack?jcu`Omni;TA]bUZE9$AiUJ-Ed.^9#6TOml>phlC!_PaldTLZ[-_q5>YPKiC$17d461>^PY
	QPp]<>JiBSeY_VUDk(1.V^EVTD^P-$Ha>riZ'nACF4Hfqse]`V)4d>Sc%@%bD:r9csqYB7S2tp"
	W[-E&r<r0Q$+"VNS5Tb?bY+F^Go3:Qj*o]G?s%TU$G+E_2*Z1-2U$J/I>FRd-BL><-CEj^[W4@U
	5EefIbd03fVoq2QDUcYorVe%Xqtd\<F]Rj.ONQ93],cFInfdC?p)pRM7e_NK\dZc4MB^%SSRlb[
	6E3,:C2T@s<+=Q'JFl;d.)5pg6A:mcT5hGIL:nWGMkQ0(1NW7L<[C.doKHe_cfiXniU\/5gsRb5
	=V>&&d:,F\>00L3jkoRG:Hs3W$T\N+Ddh3!=*a`GV"d8XR8Am2_LRiG/l5_A3p@MP/JW[5,+4i#
	)2`91X)LrViS?Tf]ppBdKb"GV78`m)3EhrL)f7b=Ih3]RFYTO8IVV*-9)5+sJ[oI-4)h)DkT/e0
	Y8+EOIdrQ`m]*rFfmO1De!9>hsY6:"!P/1<Us;dWq@J0a0sBNe9)#pj:Q37<2UVZ*0qeP?[A4As
	nf1Te>Pr*C1bAoV&=[e$4':,n.'8>Kn?0)!1rC-8WFB^Yr1)Lq;em*ZVGNhWN.oN?jWR/7*9./5
	;(YgX)R&a/qb;6W16Ph*UNk]<*ADZYaS4mjD4F=n*d.8^HiNAKND)1Q:CFH43k;@q@"DLtYidMG
	&H3T3Tg;nM[:ZTYWWLC`$mS2Mf<"+2$5.$8;_cG/cT*Ld,Mg;6<BgqoL=3d1+^pD7)C-DJc3@,I
	P"-@6Z7N4TPgMPK:fJn9PGO^/U:cEa6l2F>uEr?YpPqhU,$ErLt"Y'iT?h$'72ll//=[duF!^`E
	GuO+!\>d"hj$Il(p_\>a*GHb\5(&IJ2L`K5oqNY#ngZGPuVF.OdT%Farn1"4-m&Tj)b_`-sM%FV
	B1EHZ9a#dbI;-:U-cf?8s<X-',$&J-BjO3N1'%Qf;RK0rF)sh>RQ2c/#OahL)C-aU:-CJ22)Sr4
	&jOS>0R$X[[O#A$G`,iO@DrVUi.>2@Vk-%<&I^VJn5_IIicuq/]e#MO^`141!AQ;S2+XaP6KFXP
	<&b&6`9cP7=<<*&\r;_3qY-\t411HIU;oK"L?u=IFM+A^d?qHpcK9aPn%@IAC<h&S'N>APbDdo5
	Hr"!+r[:[+D:J8)'`]kc6SUK66a+ZJC4"pg*t?q"2ZQ5Cfeu:/$J_W$GHl?9LBdqNPYZ\XP@r%P
	TX[4%jmZf][WZHH@q.OD(D+1_(Z@D+6&a0O4#Q3@FC;C4q_QA`:85fM1KlcXr$+0HJG=H$uaKk5
	]-43QD-Z>gdf\?R'?UTp+L'677]X8NaH.g"\=9=*XlkEQIEaG8tUo]F8'o]A<-7Y;OL:]oOH/7?
	gtGMAH'A@rZtu,]+n]Qj9-kk4qb.c841F[ml5G,gk`q'T)`RiWF1GV&1h&DT]&t/23&j+;..>*C
	k%@WCG3%Fq:N&\$p[srUb8Z7C6leZG+7^j;6u1lqRR/)<a'>LDsu@c[?92j+!$S2/AaThb/(%Zd
	^PaSD7r'b);h*-ZPKh#6aTZ<t6RRTVB#gfP5VoPN[:>)@j5dilr+iq(<oh.jh2=K&S;'[Yo,i]H
	nM*h7)JgO:D94)!"[0=(c?BgTgDFK`3U[BK),hc6L!l0!fW]CHl=[(jQneS?8og/1"YB@LpeJ`L
	Gu2XW9hhF@(a+c7b,/IOKGengb/.?*^]'iL^$L\Vf?W[j,TY-(7coNQ\fT;tG`d4K&s_[\HU[9u
	i%W]KLZG1$I10)qB'U+hZF(RAG/[mhfJLP0Q(L^E4p+cU5l'IJ#OV[`8d8*u0%t`,]-eGV7<E\;
	'7,GIijgr2FV,G6]DkMFSN0,e5nu1gI<@Qd#.Spcm^Jr#rY7lQ/-G9Y]1(LX3H7]"2MilC\YG@`
	hUO/'-&m(p)mJ5D<cM@\^#amhG%g(B/N64ADs4l8kB!QV"HMj>NHC._&V*<E7j*@$"G@Wkb46(2
	^"j@^K=FK((G44^R0eQPtUX(6L27RhO%/=*h68fuRA7+\@bdbg&CP6];Z45U:KJU0u_gX(jgNeU
	0Y/Nh`Fd*Z=HYbciR#>!mQ<OqB?Ld3DMr>tJPGGm=JDD-LIUV2M>Fh$6d+P/uKp'&>tcY,a411l
	$\N4f+OOh:oj^a:?WtN"WdSOc-b%*&ki4fs=cL[Cc4C_7h'u=C&Di-A"nN--MD)Ob$mY;j%']Pd
	ee]MJ87$jdmo.'>rg(03Rh!S_o2M/KFLDG;]kn:)1&\$\e0^<ATiNk0%^'Y'*;Z5<s@lX+p,eC3
	CEE[pBrbdGF/8ZQNgV\B'g[1UnF9OJ%`.@p8IM,\>)BZf^/#?Q/S6/S=G"=4Q^2m2X.8V1tnE'V
	61fg;tiHLkrt\)a".PSt**c.9U"FXu,/ZD5l<<2Z9CX9YRjaoo40#^7DI1@>sGpZ9oQu+5MpfQX
	XoY:nVtWJgO2tgL6q#S)!aF!rgR'2#*b\MdrDp4rVnpb=<nWD/0maX9/L9M=?YI!<g&gI)t&0FK
	">[rkHOW<_MGUN%[:PP?E-s>4EM9,AEJV8T+X>\^':J6fgcM4mY^`BAa0u#pu7"/Tu(S)Y)5(QU
	fMP/1d3d;e$R&Bm1))THM?JB1A@F.!HX7lHDLBeM`$!f8,L+=S+aD:t=u]0s06<8'.5n8S""OGZ
	Bo'M'Psd@3<_4JfGaBMJ;<`1f;c:+)784LS4EX<;92]K,PQ;[aJL9/0DO1]?'#]h9-t[K5kd.?n
	D\XBqE$-hr(a6B;AZ>CW(7.MZh>ZI=u@ZZ&&`pjoR=`-<T\Enrh%l"?<<"AC=X%*i\Z1oil@=6a
	(3M6[=aT?"qo1>W>TDE`a;'R0b?&c[9f\WS-L<@cuW9k!.Q1ilcQf43\j7eL'f$jRsX+cCo@KFO
	2iAM\7X#.:r=h>S60TCFZ_45B1Vkd[VO.cMg=fSH8`jYcW%rDJPd]=d]:%1<DT[r"5W3&Ea&(k5
	^#_KuiSb*Lo%%.(6RE(rSHH&ts$:&PFIt<S?jsaqUhj3&iAfghL`Xj3aWQ^U_pnnHAh3n;l:FNA
	fOJYD`4;+YE8HX0cc]QG[)=()Z&?kDE?'T.=g#kA37JFl4i]q_LsXA)^.\=t?.=iOQ@P2Kg4_'<
	YHqo8l+N)+3,ibMhjD\A)[Nh!-N">s?F)p?i'36M=rUiL3Sr7IogqT.e?t*I,[NPL>99G"P1`,h
	n1=4s9AQkDD+SDki:<[W3VgE%p*64<?0d7nW'E8i5G;eE<(Of"DBmmju+IBk&qiOiWE16#"[WGo
	LdDa'P<XlW<S]G;ZP"e8M-D=>8Q7/;_)P;(QR:TADI,DSPA':%fTaFWV[HDl[Q??/=7,TNHl&b.
	Ip/GDgss)ZUiO@jdhCi!p2l,*FNMbk)o^D[==^C)VMuM."qQ+:QHn!!qtJK%8mZXV/,l=V7I`#f
	p6ka+-m*atmeXaVq&lWnd2q(gjb0`Qkc:9l3)!$ba6]X>+uT?,Wk2#V]@kJcd_.N\EFMFQ(<O@^
	HHbRGGPE?P#&;2O9M2,c-CR`s0jFhUt#f;&ZK_XAf6W[j7:#PEW"Igs*IpEBZ#+Y-gE;h;2DMbg
	N'Q9fY;)TE@?30JV=TX^e*217%d-Dh`@.:I``J[Cnm(M!se[lW/ld29*K'PCdtsaAJ8d#EH3VRb
	5!YSURQrNt#i*NH;/F*4M(2:YN"(ZB+F(0E<*_f]SH#h7eWVW;U>[Zl$Y*Or4C1r66&]j69dFF0
	io0@-])#Z.qa$5m&"jg9sIeX$+VEA>2W3kP4Ue.'Qt>YFtJaS\B?/"ugYf3&CZ,-BW."R)h["7k
	tmsc_fQ>BF?&'iU3nJr'.i\=4:JHifJG&k/O8I,9_dYOt_(`g-7>I6e,oZ6g2jKrr<^M4CU/W02
	tmh`gdX4=QAsQi\hm+7S,(0ZD;U>Ui=tf,o+!K9_B7##JF\Xab'en"B.^kU_0%"A_[EEOc!U'-Q
	[)XOIUmteHgaqPVt3$,E[i`_=8%j/@FdmX^sed"u8\@@nc\;ikOj#DgA%G/J`:"RG-H'O=e6M0q
	@ZmG>Ph1*J(A\eF$frG?Q%8iX^h@[Y_(<LloSp1+k]1a-VAXgj),.rN<eWX1e0^ZVJND_`_+H?W
	V@!U3NgY[^9T8OiCD73cjUZ9<cmRkIG@H9s;Ju2Wa:*>%f,j8uOA8K9M@FF736h@q>"Q"oeS>C%
	Q>P]T,IRGX=J_JPn;2iJHuCEKTU/eqCl?Snk1gOEbg1+M!5BgLqIUZ['cA?NjZr!9HuZXt[goo`
	DQk2e:KC5D?LpoZ\.Ca,;(,p\I;J.i)b&CK\+712t(?"Cuo4",b5uD.m]&/*_0>i@C=D@qDM&\n
	0A-d``<jR=\'][j;&rKjZSpkVL4DXO`3T[3g&](]GV'VC6Q\2n'?$,]&odXhF9^:^&>OJQ0,"])
	mM.@Sb7"K&GNDilR^/)bD!@$h#XZ"5n$#`4GO8M0!WS)WoF8L/]n#;1Niqq2XBQJpQ%J$AkZ*ad
	jdpU3f"p(*_Ald<%H@'$AAbhA@Hk.k<*:rqg=.'!+[M!pB1&74$3hMj(n*d-c!_)m6$;lFLQ8SY
	oWE_ZND?EG[C!RPFQ$A7P&fpph::W,T/60:qR,:SZU?Vgf\\+luk.QSQY&EiD8O.Y!->E!NO?&q
	$Afb]Fa<J@k?2]uq31I[qG58X'35c?f0\`"/nq<(Zu$Cp^nAQ$slkNMYme)q3oTTje***_BmY..
	tk"!'MdI/^Y6G`]q=YL9]D+U&7=R=Z"33L(n:X^>aP.3?:#\i\QMpGr6=JU.Djl[G*hd_6a.ADK
	r`aFQO8$qA$>(,enRTX9'Ymlp@"I4ia[7/JXmVB^71OK/H5m`P+(XFNCRJe1>_8MH3&e.!GF^"0
	!aS3oGA8-D;-iV`)r@r(>OQYdZM>/95L3gng5H%%rCf0R@8P49<5kEbe5#F"(I*$iMCm*qcY5&A
	rWM=[e=^"tW)p<,S@K[.86e"%%4bK3%2Rq!W]fYB8M\S"hf\Eaj+]OKjHlJ2)X9g,K(EV@Q"j]:
	#qCBr5QE!,^RmS]NkFT^>\R.4=FblJ"&!MFATo"ZdC*d='?I.u*EI@GFZX4AAea-9hs`4YG;k:Z
	<IPcJW-:[tZ5Lr$C$eL]2kD?ATjWgmQVp`i+VDJkM#h`m*<N&jRhuJ_].hZqG[R[Z*0X]Z=0PYg
	3E&qU@Ft)G=R*>Q'[Xnhpkcjj*pjN"=3n`G943IMU9UZF79pjb(jjOU\I`]78?UrV;5Z"7fgmX.
	"(kI#7+;k_+4_4'M8,C3m;%S?6@351cl2Slg[_GYIiqpeX0^d7(`T`_K*>*QnB^fq*WQ<^LE;S0
	gh`fWqP4^_uBfK@@"F\Ym\`IcBJ>/*p^/RKE8B`0Sst2^C/[bpQKl)gOZ@r(*r$/k@m3(j"!CDr
	M4@g;cdNk/u[48I]KK&!efZk!2F%4.gnA>d/jFXNmfi7Qf)j4S-J)$.Lj2:2+N]=nWpm>DADC,0
	iN8:E-U[*eQYAeP`bgX\N&AAPq8(c@PJO:(kgQlaLT.A-3p>!J2"&g'8LEH0KorNd-DqEXKj(4>
	\8Xk3d@NG>VSu>hh_V85ORir_nlkc<3[ti,O=3f?dP*2ea9b8LD_[m]ESNe!ft5Lu'nOO(/EaD[
	W)>g:>K6IQ6>uCtj?N%U6tKDPoAOY6K6(;jD3+HUO<7Cr2-:`oE6K`Gfg\c>YMhXu0Up85c9IRj
	`NB_V0Zh/\RAs@5bRPc[@ec`g@X`1\2US*-EBq.\e;:pCs@MYTFB]C&SI&l>^\n@s34"K.ch&_#
	POX:S8_B3N"Ws+!JmBg<YOb^+07i`pggK1o23cCs(j)i,1\L_#r3;^2"=*Vdie"f/7:8bA2s&,o
	1G$V26@Am_BeTHM_mM:R3nQFYf8NC%aQFN>d/U/)=daSg(mQb/XkUc.bBWX`a4\e.Lj63@?_1c]
	.?/<q*665m`9KCm`tfql=bM+[#c)$\A<XlCq+$RSp)N.si@%pikcl^6b:Q\qZ>)Sqh#pk\kj'Bk
	=dX;!ff#!L!A&^uX)]X)dhqGgT<!/s5[SGctB$[(G-T))ST[>5nSu?&5Ag7`eRQq.;K,&)lUAl:
	VO+=Z*1kBgFUddc'_.SYZ$UmeJt*iS3\CB%2eu$PIMn&8"+ESM=_c;Zs!`,9-d#f:>rIcHi3A:-
	>Q?o6DJ*r#'LQCA[+Egd9ECh.tGpV7A\2ZE+='q4o9fEIagHhC\+0L[aTT2q%V2i]e'#ZH=aF8V
	Ej//9[&>,2kds1H^GG>]0@'")lB4o;lDomb+,"QH8@(8+@3f"R<E6%.RNd2O58?2fMkE0YqN=]H
	,HI\AYM8-NpaRgl-t&Z[C/;)>l'2dXE?e:V43hNRs!Yh+$i/$Z&825knG_AjX(o-<A"m%M(PS!%
	,59Bh$@<:?gWUKgF``'mL=$PJWcRm[F@MS!LIM7#jbeSmZ[`r2]T4qGu3GHC=&aL98M9^E<ANq\
	GIV9<iK6C0(d\@nS4ZMFcGdN]-qDrZHLM8\q:RA$IK)]h4n.Hq3//J&FD(c+H)sr2Pk4fZ)Md+G
	XPr3#bHDO92:LE_etn.T&i8P>/BFpi58N]DhjJ^#YVR\[Ac^XUOKBPI\Q'C][@9+92]n!KOQdG=
	98MRslX1m^uuf=UqLkqg2%,BV7oUNo;SNKTgr#>EQF7Gi4Nk@lUK?8IBZ[<-96>phP67buW[/D0
	o<gdcDu&J2*W<`%D/ZOu;'G5pING5+6@TZTS*9LNP*V6V=q:Gns4dJJ_S0Zo2D*66qiC*cORT,i
	XeNeC)tK!,5dSGiQfPH:Nh)4.oqpQI4j`:V<rLf&AAG`b-ZCR"8"'qo%NdK,5K?9iS7"B%t@4(%
	M"**O_N<l96-UQ'JJtQ_[d<1sVobgBo1Io.u"DkE!=Xj;M9d?OIr4?c6tk(&3!LGcKbM>q9!d11
	![6Q"_OtP2-u8_jP%'!Fh*7K#]*M-abC,07ASgm4<[&i"(Om^(esGDD]ZDl5G>Sk'K6i?O:.L\m
	rsY4>atV!8ELcj;t*cU>=QRm40ET3kpCH4_&UEZf6856C(MlCOlqQ15*aG52p/t[Z/<.6S[MN#0
	B$PgZWZ=T8rUC;b`QP%f8\]m0KdN$OEMj4)98T07\Ge#p^^KcX3"AB0B_s01N<'8&W.Xli&\$B^
	k@Ip@]gjee1Va$H.r0Q:![M4)R9pFt<\:Qa8U(gao&;Dr=>7`&D$92!K+cL:Y*[%DkahG;3kB$l
	XM?\[^>+E2D@L1diUq!'AYUXU/ag;sN"_7jisfjQi/;ghm59g0LlLVT*-m$/6<=4(DS5S=`GND'
	Y75Q*k7sGc/Pf)Y#_JFtUF-B^s&]p1q9W)W@7;MhLYsg.Mj;!TVe9Xl>f5@jAlT,(*\kD4l,d;:
	+qE12HhU:Uq5eVRD:`_),[ZKV9PlYe,J?5pU*?.iQqQ2.ZCHBhf.6<MB":SZ1H?Q>(64LX!<<R*
	-0cH$;GDG2%]VX?Q(Q"i0CtH+RAT41?R,a+uRE"gsMqdTk\H91p^/'BL^_:ui>.0E>T*&,)r\AL
	-"8,d^'%Fe_C/C!GXe)!Z-UG&]X,gXmI$UQT(&R*+?<J,h&(!+W3,,.6N#[s_DAhuqNZ[/1pQ7s
	T)u/Fm09]*E2Y@<YEB8LJ83DKbhWV`^5B3pQ>W+%1.`.arMN%I1NsLh5!%VN*A(]4?jk2jY]Ajk
	#26"Hf59e.)M]Tg!Xm^TTsM*aa2]'1jggBrG;$YZfd+7)R6(45CJ_+#/hNJoIKV%Phg(EnN6,n#
	AM0qGV;E%3]gBr%7JIn3Hi"9&3d@4U63iGb0!b)0T-ObI?S>GU)h"Bh]$WP%p.`US\)Lj-8B@c9
	N679k7'rC<[4LmG'%&fCtk7.chC3S`@4iNXnlJWfYG1>Jf+_N:*llXW]??$[Emr]jq*qi#%:DTd
	9ToPS)$`f!P0tMc[/j`82Z,`"ql!==p)N+MeE(&Of\:!+>@-HKXE9&q.*D[_n<>^[R<BYD@WTl,
	)Io[aGde$XS*jBj5KY7[X?'GB,],qaB^i]3A1.$`i/Pco"USINJ"1NO9.03,WY(Pj8BWh8pVWN"
	nu?<T0Pqn2#YNmoa]i[5?u:kVL<[!/,q^]3FZgQLD*I4Kg@p5bsR5kAapj\DVQfYAFA/RX%t:Sn
	ZHQQD-^'[g3k%*$0`_:/29p4_hD@SPRq\8"-8YPp<,.OlbFOJiIBg+?5Go)itBp>K9Z#H,#59C%
	q5R6c;S_:jL&G5L-ZsVGB[&1J#fK$,H0R3BYam54V_fJ2dTB^`7>g/HkeiVqjo?c&</!p=BCf^f
	^DCOc8\lO?.\e16K&@poaVs^qMaXl0OQrPac-/OBo<UJsj^U8Do&MqGp0<f\`OO[4H26k/Q7u!j
	o55OM(Z>[::Lq?r',e:2h[T6ff["ONdU#_h4Q?R#HBup2-n%H=6B<@L"KmM<ZRDa3AB=i0D,BPQ
	f8A'PTJ3>D\dkAR:FXBd]lMQttObdC#N3.B[K^1.8pY.Y(="33AAjUWT]f([*Pg;dCX]#&,;oN4
	r-drfq[PQ!Df-`gLbCpod],L--`+5Y:,A*.iOcHD6QoQaI2\YAFcA1'b5rdAi>OJ4SVG[\M_Ij^
	3l`D8)7#[oUm-9g"K$<<60:D;uW.pZl#'Z&H%Pe&Sn:>3jlGj@W<a7*+FDq6i>LDe&C1S93bj4.
	48d::eon3f^Q)D/'H:LM>\qf4F8=nkLAo2S]]d$Q.ZD:^Q/-i+"+!c'-T92*Eq`Se^a\\@8r62c
	hoh;D^=2).<OR+Ae';$Li,Yp#OUZPL."oViL%M?0\mg9^Oc:VSjcG:tQ/rCiP?dSuYe]VX4!%Mj
	hqdi&gr=KmkN#FUNu>eF_BfbVq'uJV[p!4#,M#H0a^!;lM:R$C%<$*iF&jeUAX_*6c8J/U&a;_J
	XQobXZ`+7VgA64NQi^lP_k,i9q)!JE`7h$J]A3&2G$DKaBPS4`ZIEhZC@D;j+n`druY@Gojet7K
	&_71k?O@qfdkQ.HHh^AR2GCI54C7:MT%KDoj"KH_.=fnP=ok2/a>s&^L[`lINs5;tE?o&%J;tFc
	H^Of@(G/-ctqh32\ZNhtTE.d]IBQ/1lR0P"&D<D=Ra=+M/<:ZYULgF4]!LMg)ciS6!^\_-8<>4?
	0AM@R%88>(t1rE_EO^"0\pNPtatW$>Vu:^Nh/si9_(['+ho;1YdLVmos:3-TNE8`EZ='Ij/FZOl
	IJqZ<n2k6$ka\g?K'Hh]boIX):1t$??VG9-//t)VSO-bZ"8;FWV5Q]10B@[dk/1>[7P#<P63-7j
	.F)5QdYsoeeEl<%Ia8h59_/M,i`,Op6bQ<di^iH%iIt:HMXl39$q[$7:69-h.D/DD[d?g%)JnKo
	[gn@O)B\9iP?1`AFZ$e9(I:/N(j#FtLA35oSp:Tu\4%'N9q%=!C8Yf]9[Q.@3Wr]u^U.Sp+7D3p
	h(1ncS,^'1k0YRZhZWkUeu2Z[OhGLejrhJbde6Z`/Zo><D(q\,enfgj-s$.UM="2JdUc9=<>5<M
	nO,`$U.KaqMT797KRV[%&8m25M$:UsA/BP-MC'J:*84[.c2r_\NLp%q436J-tG:VS7lCY,^?V&`
	?A5(:KN*dNl.a?0"Jm*+/f=_jo=aBfju.UBPG"r*=>"CO>r*87IPnJ%Lk=i42%L#R5ac1o&@FAQ
	=,WUi^6DLVnEAK388]hcdG<bg">PhHiInAJjVb/"JUs:!9<:d*efqbLKkhKXlH,dd0^A-?rLS+#
	hCR:SrI3mVB7(PrU(?C?#pE[@<^6rr?-LX<6ePQJf8DaZH,<dd<3<`+,EI"ouVRb,&fF<mJ>JhD
	*CupP^_o5k'a,G,bpQ`p4%.:R3oIb`r<K,RfiWaZiD[UqNTn(Y%ZJmQn8-nbm7B)RZ]4KSt7%1.
	<[D_MGu>T9Eq-F.Pq`p[=_C67oT`lVl,MP)=H>[1<u->aaW@39>!@hUCi^3HE86)(."goHPF,ir
	sp:M9>)?U.;,++%j#nr)\;lW.r$X1lW3p`IQ-PERUGL3dXp[=3C`AU!lad;f5cm`RFUG>1W&D!h
	12k_HGj*NHV"(dl?N``rpVZWOF(0>IHWb\L4[Q/$Ea?^*rb4*i4?Eq/1)p^QTK@'M,;j#butF#"
	cqte[S)>B,L7b'dZb8Pe*JM/uN]br)_?`/Xp=Rk+)$8KOgB=.\n-!(lWR>W9UI(cUf3Gr&V;edJ
	R-sQ>;:mOuUR$&/:4r%t"`$YJh@SRoB)oq]h6RDe=J!8%m*"S>lc=KH!QmI54onkZUs4k2)]-KR
	@pm-IAk(Xe85Pj12^_@j?Qq7bIQKM6<5\GFPSV.'@GoQTf$NCpSAM6h-uH;`YbsUqPFs!-VLF'j
	DfDJ2-k@N7Z?VRroOHopBtM9s5cT`4@K8>$d,c,KanA*Qo)J$\SpB!#WQMBTB4MW@K2li)Y[>N4
	q"@CJE=8Bl/O"Pba"96ubjLW'6^#+7Q1082;X[,^-c&Ji)kAiU3K#X2_Z5;O5TIm@J=gQ:Y^W3)
	e,LX?Zo[K/p"db5"o^CTFeb^*?k^!,$dkH#btQ1rNk*N!r9#irdq7Z$/p0b=?&T;t-o\Q/\tUGq
	V1Cm%VuJ<g2Z['$nl+"+W>/kVJ7tl%uGtcX6HOCN&3.Jf7+\X$ANo>@,gUZb!i[G%Xp:d^uM3G)
	cAa3E*s#(!S&n1TEYG_0E`5GM9J(\YS$%*XHCk8H?\d&gOX^*!B)5(Dn#L)'mYl;6rQ3m[8jhl^
	"$Vg?WTDQIA=2Sgfe@i^5b<M=p\*4b$_kplQY0SDT"$UQ\aK0U$SVP0gR]DWSndf@IC<lt!\u5J
	d@"4'_9INO:9pWRU2$"HhG.qd>Pk+WK&.Y^%59.qjUIZ]k0C:PSd`RWX\Zd4S)fkP]+&WWCr1(u
	R"HcUnhsEnic5Fa#LW4Z:Si\Ln#/;AGY^;J?.L_>2TAdfAqm5W,8k-J#mRC\fuH0?<d=hP:sJ'O
	?7UE5b-#_ri&X"5g:>=0QSgVnO0r0>j7)_?KH=hLfBZEMdIW.U$)4T%[X_B>^OHg]lgC+EDh[CL
	,,kO.?1pBi][&f4DJ?D:_QX6Im*.D\Fos"#9V)H\inea98#GN".>+Y`H(R!rR63*RBB1kZ0bn,I
	Dsep]<qO;?_S3VWW+R'UHODE#AF(/OD@3>gE%,SFCrtVo9Z*ACPHo`bA:IVUOAL5_^lF<LK5Q"k
	su85i<V_%9V!=mltDKL\c.ghp%uhWSL++/@&VXc=I-/<J\I9k3McU:cDdd1>ntp5%bRScg>L#Sa
	[:]n?q/+Hp+7hpU?KK%(?l'q9?0S=!0"+TWnSNNSc/#'In*`]U#88hM7NBn^kce%mCK.e+Gi@F0
	*MhgdWSMN'th@4>US=a^E'VH@Te.0okW=\MMW\!TSYGr-6iclRrip_caC%mX.V)Pq#uL2[."6+'
	ebilmjO0`_Arr'c8:*3kkgmC=C&6+kJOppH%)2Dr_k^B&W/q@Rheb7OJO<j-I^F`_!.-Dd/IcOj
	.[19V2ePY82@1_`FB_U$,[.OhYmEETCA2cQQ<E4NIYbZo8=0=+QHKQF,FPD:I.,;bm9%'H0SYg(
	o[G>u*Se?!4ka*V_&!Q$uO60o#*,,<\UG#jU/$H6e-\>4):$IO`\f\1q\YArpm^i!?DO9#!>:^p
	`)\!]ldN-"\[b6d!&!i`WZp)U,msX>bI%dm\D-&eT*QW&R''SZBVf0u+ONOcauYn/[M?LqGb,f=
	AOTI^(3;[m\@IS!"u9CD$.*`Z#pa,E1#Io#7sq/nU;*jL:&aIgS&-;bfc=98K#k#![/AP.B;A)(
	,g8(-E(AD=8`W7a)aX)p'oYL;"7HbD4HPQ>(7hRSlM(EqhrQ.4MdbAViDpJ/Zj6QW-W3.+$C!M^
	Z5Bj*_+K4H2R#Pf!jK.u)4pbj9P$bX?2+q*<4*X*kir9;BMpeQ0[&'F^P.G/8!E.d:0)4c'"fNB
	^O),>c6]2^`jqe'B90U1"_<\6\XH0_o!bNBU_/)`Jc8EK?r.=b5Q_WDcTUi&TURRK<cR<6>CMIb
	cf@C'J-l?LmM97eU&5gT*o/)5Io"9[PjD#lDb1j:W!.2*ho-[(d;jQ9Pba9d7V[]<KbeDIF45gQ
	`-s8BqX&$CnU.jaNuUZ#Y6:)Y0pUI4=.r*oGrF_u%,;8+RsB-UEUVD;ITf=]pS:Po/<;J9#t-:K
	*j#h<WS;q==+Lm<fkNC((9bp9_U!'?u\=k6a*I5Ss`bKBq*qNjnQmf][I+.c)6X:O:14%6^:BXe
	^%![L=PlJV(oP:FE(^q+FotjKJJcF5`KCk\]\Q/e,do>tZd*WlZJIk<,?k!'ZZ=&-(;
	ASCII85End
End

Menu "SP2 IGE"
    "Open main panel", BCIGE_OpenPanel()
    "-"
    "Prepare timed sample table", BCIGE_PrepareTimedTable()
    "Open last timed input", BCIGE_OpenInputBtn("")
    "-"
    "Recalculate AquaDAG calibration", BCIGE_RecalBtn("")
    "Open calibration table", BCIGE_CalTableBtn("")
    "Open calibration graphs", BCIGE_CalGraphBtn("")
    "-"
    "Open results table", BCIGE_OpenResultsBtn("")
    "Open results graph", BCIGE_ResultGraphBtn("")
End

Function AfterCompiledHook()
    BCIGE_OpenPanel()
    Return 0
End

Function BCIGE_Init()
    NewDataFolder/O root:BCIGE
    NVAR/Z v0=root:BCIGE:AQ_rBC_fraction
    if (!NVAR_Exists(v0))
        Variable/G root:BCIGE:AQ_rBC_fraction=0.87
    endif
    NVAR/Z v1=root:BCIGE:DefaultLiqFlow
    if (!NVAR_Exists(v1))
        Variable/G root:BCIGE:DefaultLiqFlow=0.109
    endif
    NVAR/Z v2=root:BCIGE:DefaultDrainFlow
    if (!NVAR_Exists(v2))
        Variable/G root:BCIGE:DefaultDrainFlow=0
    endif
    NVAR/Z v3=root:BCIGE:DefaultPurgeFlow
    if (!NVAR_Exists(v3))
        Variable/G root:BCIGE:DefaultPurgeFlow=1
    endif
    NVAR/Z v4=root:BCIGE:MinCalR2
    if (!NVAR_Exists(v4))
        Variable/G root:BCIGE:MinCalR2=0.995
    endif
    NVAR/Z v5=root:BCIGE:KeepPBPData
    if (!NVAR_Exists(v5))
        Variable/G root:BCIGE:KeepPBPData=0
    endif
    NVAR/Z v6=root:BCIGE:BBHG_slope
    if (!NVAR_Exists(v6))
        Variable/G root:BCIGE:BBHG_slope=NaN
    endif
    NVAR/Z v7=root:BCIGE:BHBL_slope
    if (!NVAR_Exists(v7))
        Variable/G root:BCIGE:BHBL_slope=NaN
    endif
    NVAR/Z v8=root:BCIGE:BBHG_intercept
    if (!NVAR_Exists(v8))
        Variable/G root:BCIGE:BBHG_intercept=NaN
    endif
    NVAR/Z v9=root:BCIGE:BHBL_intercept
    if (!NVAR_Exists(v9))
        Variable/G root:BCIGE:BHBL_intercept=NaN
    endif
    NVAR/Z v10=root:BCIGE:BBHG_R2
    if (!NVAR_Exists(v10))
        Variable/G root:BCIGE:BBHG_R2=NaN
    endif
    NVAR/Z v11=root:BCIGE:BHBL_R2
    if (!NVAR_Exists(v11))
        Variable/G root:BCIGE:BHBL_R2=NaN
    endif
    NVAR/Z v12=root:BCIGE:BBHG_efficiency
    if (!NVAR_Exists(v12))
        Variable/G root:BCIGE:BBHG_efficiency=NaN
    endif
    NVAR/Z v13=root:BCIGE:BHBL_efficiency
    if (!NVAR_Exists(v13))
        Variable/G root:BCIGE:BHBL_efficiency=NaN
    endif
    NVAR/Z v14=root:BCIGE:Nstandards
    if (!NVAR_Exists(v14))
        Variable/G root:BCIGE:Nstandards=0
    endif
    NVAR/Z v15=root:BCIGE:Nlevels
    if (!NVAR_Exists(v15))
        Variable/G root:BCIGE:Nlevels=0
    endif
    NVAR/Z v16=root:BCIGE:Nblanks
    if (!NVAR_Exists(v16))
        Variable/G root:BCIGE:Nblanks=0
    endif
    NVAR/Z v17=root:BCIGE:BlankMean_BHBL
    if (!NVAR_Exists(v17))
        Variable/G root:BCIGE:BlankMean_BHBL=NaN
    endif
    NVAR/Z v18=root:BCIGE:BlankSD_BHBL
    if (!NVAR_Exists(v18))
        Variable/G root:BCIGE:BlankSD_BHBL=NaN
    endif
    NVAR/Z v19=root:BCIGE:LOD_BHBL
    if (!NVAR_Exists(v19))
        Variable/G root:BCIGE:LOD_BHBL=NaN
    endif
    NVAR/Z v20=root:BCIGE:LOQ_BHBL
    if (!NVAR_Exists(v20))
        Variable/G root:BCIGE:LOQ_BHBL=NaN
    endif
    SVAR/Z s0=root:BCIGE:LastBatchFldr
    if (!SVAR_Exists(s0))
        String/G root:BCIGE:LastBatchFldr=""
    endif
    SVAR/Z s1=root:BCIGE:CalStatus
    if (!SVAR_Exists(s1))
        String/G root:BCIGE:CalStatus="Not calculated"
    endif
    SVAR/Z s2=root:BCIGE:FixedSP2Calib
    if (!SVAR_Exists(s2))
        String/G root:BCIGE:FixedSP2Calib="IGE_BACON_20210222_DMA_AQ"
    endif
    NVAR/Z v21=root:BCIGE:ParticleRow
    if (!NVAR_Exists(v21))
        Variable/G root:BCIGE:ParticleRow=0
    endif
    NVAR/Z v22=root:BCIGE:ParticleSizeBins
    if (!NVAR_Exists(v22))
        Variable/G root:BCIGE:ParticleSizeBins=60
    endif
    NVAR/Z v23=root:BCIGE:ParticleMaxPlotPoints
    if (!NVAR_Exists(v23))
        Variable/G root:BCIGE:ParticleMaxPlotPoints=5000
    endif
    SVAR/Z s3=root:BCIGE:LastRawDataDir
    if (!SVAR_Exists(s3))
        String/G root:BCIGE:LastRawDataDir=""
    endif
    SVAR/Z s4=root:BCIGE:ParticleStatus
    if (!SVAR_Exists(s4))
        String/G root:BCIGE:ParticleStatus="Not analyzed"
    endif
    Return 0
End

Function BCIGE_OpenPanel()
    BCIGE_Init()
    DoWindow/K SP2_Toolkit_PSI
    DoWindow/K BCIGE_CarboneNoir
    Execute "BCIGE_CarboneNoir()"
    DoWindow/K SP2_Toolkit_PSI
    DoWindow/F BCIGE_CarboneNoir
    Return 0
End

Window BCIGE_CarboneNoir() : Panel
    PauseUpdate; Silent 1
    NewPanel /K=1 /W=(120,50,960,745) as "Boite a Outils IGE v2.1"
    SetDrawLayer UserBack
    DrawRect 12,8,828,278
    DrawPICT 30,12,1,1,ProcGlobal#IGE_UGA_BC_Banner
    SetDrawEnv fsize=11,fstyle=1,textrgb=(0,17408,34816)
    DrawText 26,294,"SP2 IGE | Timed samples | AquaDAG calibration | rBC results"
    SetDrawEnv fsize=9,textrgb=(20000,20000,20000)
    DrawText 670,294,"IGE workflow"

    TabControl BCIGE_tabs,pos={18,304},size={804,367},bodyWidth=300,proc=BCIGE_TabProc
    TabControl BCIGE_tabs,font="Arial",fSize=11,tabLabel(0)="Samples / Timing"
    TabControl BCIGE_tabs,tabLabel(1)="AquaDAG Calibration"
    TabControl BCIGE_tabs,tabLabel(2)="Results / QC",tabLabel(3)="Particle Properties",value=0

    GroupBox BCIGE_GB_sample,pos={34,345},size={754,275},title="Timed liquid-sample workflow"
    GroupBox BCIGE_GB_sample,font="Arial",fSize=11
    Button BCIGE_prepare,pos={58,378},size={220,26},proc=BCIGE_PrepareBtn,title="1. Prepare timed sample table"
    Button BCIGE_prepare,font="Arial",fSize=11
    Button BCIGE_run,pos={58,414},size={220,28},proc=BCIGE_RunBtn,title="2. Run timed analysis + calibration"
    Button BCIGE_run,font="Arial",fSize=11
    Button BCIGE_input,pos={58,454},size={220,24},proc=BCIGE_OpenInputBtn,title="Open timed input table"
    Button BCIGE_input,font="Arial",fSize=11
    CheckBox BCIGE_keepPBP,pos={58,486},size={245,16},title="Keep raw/PBP folders after run (uses more RAM)"
    CheckBox BCIGE_keepPBP,font="Arial",fSize=10,variable=root:BCIGE:KeepPBPData
    TitleBox BCIGE_timing1,pos={310,376},size={440,18},frame=0,title="Rows may point to the same .sp2b file."
    TitleBox BCIGE_timing1,font="Arial",fSize=11
    TitleBox BCIGE_timing2,pos={310,397},size={440,18},frame=0,title="StartTime and StopTime define each measurement."
    TitleBox BCIGE_timing2,font="Arial",fSize=11
    TitleBox BCIGE_timing3,pos={310,418},size={440,18},frame=0,title="TrimStart_s and TrimEnd_s are explicit QC trims."
    TitleBox BCIGE_timing3,font="Arial",fSize=11
    TitleBox BCIGE_timing4,pos={310,439},size={440,18},frame=0,title="Each raw file is loaded and analysed only once."
    TitleBox BCIGE_timing4,font="Arial",fSize=11
    TitleBox BCIGE_fixed1,pos={58,518},size={690,20},frame=1,title="Instrument calibration: IGE_BACON_20210222_DMA_AQ"
    TitleBox BCIGE_fixed1,font="Arial",fSize=11
    TitleBox BCIGE_fixed2,pos={58,540},size={690,20},frame=1,title="Liquid correction follows the validated Excel efficiency workflow."
    TitleBox BCIGE_fixed2,font="Arial",fSize=11
    TitleBox BCIGE_warn1,pos={58,575},size={690,18},frame=0,fColor=(45000,0,0),title="Do not infer transition cuts from concentration values."
    TitleBox BCIGE_warn1,font="Arial",fSize=10
    TitleBox BCIGE_warn2,pos={58,594},size={690,18},frame=0,fColor=(45000,0,0),title="Record every trim explicitly in TrimStart_s or TrimEnd_s."
    TitleBox BCIGE_warn2,font="Arial",fSize=10

    GroupBox BCIGE_GB_cal,pos={34,345},size={754,275},disable=1,title="Automatic AquaDAG calibration and diagnostics"
    GroupBox BCIGE_GB_cal,font="Arial",fSize=11
    SetVariable BCIGE_aqfrac,pos={58,378},size={245,20},bodyWidth=80,disable=1,title="AquaDAG rBC mass fraction"
    SetVariable BCIGE_aqfrac,font="Arial",fSize=11,format="%.3f",limits={0.1,1,0.01},value=root:BCIGE:AQ_rBC_fraction
    SetVariable BCIGE_bbhgeff,pos={58,414},size={245,20},bodyWidth=90,disable=1,title="BBHG efficiency"
    SetVariable BCIGE_bbhgeff,font="Arial",fSize=11,format="%.4f",limits={-inf,inf,0},value=root:BCIGE:BBHG_efficiency
    SetVariable BCIGE_bhbleff,pos={58,442},size={245,20},bodyWidth=90,disable=1,title="BHBL efficiency"
    SetVariable BCIGE_bhbleff,font="Arial",fSize=11,format="%.4f",limits={-inf,inf,0},value=root:BCIGE:BHBL_efficiency
    SetVariable BCIGE_bbhgr2,pos={330,414},size={180,20},bodyWidth=80,disable=1,title="BBHG R2"
    SetVariable BCIGE_bbhgr2,font="Arial",fSize=11,format="%.5f",limits={-inf,inf,0},value=root:BCIGE:BBHG_R2
    SetVariable BCIGE_bhblr2,pos={330,442},size={180,20},bodyWidth=80,disable=1,title="BHBL R2"
    SetVariable BCIGE_bhblr2,font="Arial",fSize=11,format="%.5f",limits={-inf,inf,0},value=root:BCIGE:BHBL_R2
    Button BCIGE_recal,pos={58,485},size={210,24},disable=1,proc=BCIGE_RecalBtn,title="Recalculate calibration"
    Button BCIGE_recal,font="Arial",fSize=11
    Button BCIGE_caltable,pos={283,485},size={180,24},disable=1,proc=BCIGE_CalTableBtn,title="Calibration table"
    Button BCIGE_caltable,font="Arial",fSize=11
    Button BCIGE_calgraph,pos={478,485},size={180,24},disable=1,proc=BCIGE_CalGraphBtn,title="Calibration graphs"
    Button BCIGE_calgraph,font="Arial",fSize=11
    TitleBox BCIGE_calnote1,pos={58,531},size={690,18},disable=1,frame=0,title="AquaDAG levels: 0.1, 0.5, 1, 5, 10, 25, 50 and 100 ppb."
    TitleBox BCIGE_calnote1,font="Arial",fSize=10
    TitleBox BCIGE_calnote2,pos={58,551},size={690,18},disable=1,frame=0,title="Efficiency = OLS slope / AquaDAG rBC mass fraction."
    TitleBox BCIGE_calnote2,font="Arial",fSize=10
    TitleBox BCIGE_calnote3,pos={58,571},size={690,18},disable=1,frame=0,title="Corrected ppb = raw liquid / efficiency; intercept is diagnostic."
    TitleBox BCIGE_calnote3,font="Arial",fSize=10

    GroupBox BCIGE_GB_result,pos={34,345},size={754,275},disable=1,title="Results, residuals and quality control"
    GroupBox BCIGE_GB_result,font="Arial",fSize=11
    Button BCIGE_results,pos={58,378},size={200,25},disable=1,proc=BCIGE_OpenResultsBtn,title="Open results table"
    Button BCIGE_results,font="Arial",fSize=11
    Button BCIGE_resgraph,pos={274,378},size={200,25},disable=1,proc=BCIGE_ResultGraphBtn,title="Corrected BC graph"
    Button BCIGE_resgraph,font="Arial",fSize=11
    Button BCIGE_qctable,pos={490,378},size={200,25},disable=1,proc=BCIGE_QCTableBtn,title="Open QC / residual table"
    Button BCIGE_qctable,font="Arial",fSize=11
    SetVariable BCIGE_nstd,pos={58,426},size={170,20},bodyWidth=65,disable=1,title="Standards"
    SetVariable BCIGE_nstd,font="Arial",fSize=11,format="%d",limits={0,inf,0},value=root:BCIGE:Nstandards
    SetVariable BCIGE_nlev,pos={245,426},size={170,20},bodyWidth=65,disable=1,title="Levels"
    SetVariable BCIGE_nlev,font="Arial",fSize=11,format="%d",limits={0,inf,0},value=root:BCIGE:Nlevels
    SetVariable BCIGE_nblank,pos={432,426},size={170,20},bodyWidth=65,disable=1,title="Blanks"
    SetVariable BCIGE_nblank,font="Arial",fSize=11,format="%d",limits={0,inf,0},value=root:BCIGE:Nblanks
    SetVariable BCIGE_blankmean,pos={58,460},size={260,20},bodyWidth=95,disable=1,title="BHBL blank mean [ppb]"
    SetVariable BCIGE_blankmean,font="Arial",fSize=11,format="%.5g",limits={-inf,inf,0},value=root:BCIGE:BlankMean_BHBL
    SetVariable BCIGE_blanksd,pos={335,460},size={260,20},bodyWidth=95,disable=1,title="BHBL blank SD [ppb]"
    SetVariable BCIGE_blanksd,font="Arial",fSize=11,format="%.5g",limits={-inf,inf,0},value=root:BCIGE:BlankSD_BHBL
    TitleBox BCIGE_qcnote1,pos={58,502},size={690,18},disable=1,frame=0,title="QC: R2, recovery, residuals, time-window validity and missing data."
    TitleBox BCIGE_qcnote1,font="Arial",fSize=10
    TitleBox BCIGE_qcnote2,pos={58,522},size={690,18},disable=1,frame=0,title="LOD/LOQ require at least 10 independent blank measurements."
    TitleBox BCIGE_qcnote2,font="Arial",fSize=10
    TitleBox BCIGE_qcnote3,pos={58,542},size={690,18},disable=1,frame=0,title="Without 10 blanks, formal LOD/LOQ remain NaN."
    TitleBox BCIGE_qcnote3,font="Arial",fSize=10
    TitleBox BCIGE_qcnote4,pos={58,562},size={690,18},disable=1,frame=0,title="BBHG and BHBL are both retained for scientific QC."
    TitleBox BCIGE_qcnote4,font="Arial",fSize=10

    GroupBox BCIGE_GB_particle,pos={34,345},size={754,275},disable=1,title="Single-particle rBC properties (on demand)"
    GroupBox BCIGE_GB_particle,font="Arial",fSize=11
    SetVariable BCIGE_partrow,pos={58,378},size={210,20},bodyWidth=70,disable=1,title="Sample row (0-based)"
    SetVariable BCIGE_partrow,font="Arial",fSize=11,format="%d",limits={0,inf,1},value=root:BCIGE:ParticleRow
    SetVariable BCIGE_partbins,pos={300,378},size={190,20},bodyWidth=70,disable=1,title="Size bins"
    SetVariable BCIGE_partbins,font="Arial",fSize=11,format="%d",limits={20,200,5},value=root:BCIGE:ParticleSizeBins
    Button BCIGE_partan,pos={58,414},size={205,24},disable=1,proc=BCIGE_ParticleAnalyzeBtn,title="Analyze selected row"
    Button BCIGE_partan,font="Arial",fSize=10
    Button BCIGE_partall,pos={276,414},size={205,24},disable=1,proc=BCIGE_ParticleAnalyzeAllBtn,title="Analyze all rows (slow)"
    Button BCIGE_partall,font="Arial",fSize=10
    Button BCIGE_partsummary,pos={494,414},size={205,24},disable=1,proc=BCIGE_ParticleSummaryBtn,title="Particle summary table"
    Button BCIGE_partsummary,font="Arial",fSize=10
    Button BCIGE_partnumb,pos={58,450},size={205,24},disable=1,proc=BCIGE_ParticleNumbGraphBtn,title="Number-size distribution"
    Button BCIGE_partnumb,font="Arial",fSize=10
    Button BCIGE_partmass,pos={276,450},size={205,24},disable=1,proc=BCIGE_ParticleMassGraphBtn,title="Mass-size distribution"
    Button BCIGE_partmass,font="Arial",fSize=10
    Button BCIGE_parttime,pos={494,450},size={205,24},disable=1,proc=BCIGE_ParticleTimeGraphBtn,title="Time stability"
    Button BCIGE_parttime,font="Arial",fSize=10
    Button BCIGE_partchan,pos={58,486},size={205,24},disable=1,proc=BCIGE_ParticleChannelGraphBtn,title="BBHG vs BHBL"
    Button BCIGE_partchan,font="Arial",fSize=10
    Button BCIGE_parttable,pos={276,486},size={205,24},disable=1,proc=BCIGE_ParticleDetailBtn,title="Selected particle table"
    Button BCIGE_parttable,font="Arial",fSize=10
    TitleBox BCIGE_partnote1,pos={58,530},size={690,18},disable=1,frame=0,title="Particle analysis is separate from the validated concentration run."
    TitleBox BCIGE_partnote1,font="Arial",fSize=9
    TitleBox BCIGE_partnote2,pos={58,551},size={690,18},disable=1,frame=0,title="D_rBC is the rBC mass-equivalent diameter from native PSI post-processing."
    TitleBox BCIGE_partnote2,font="Arial",fSize=9
    TitleBox BCIGE_partnote3,pos={58,572},size={690,18},disable=1,frame=0,title="Optical diameter and coating remain disabled until YAG/LEO validation."
    TitleBox BCIGE_partnote3,font="Arial",fSize=9
EndMacro

Function BCIGE_TabProc(ctrlName,tabNum) : TabControl
    String ctrlName
    Variable tabNum
    Variable d0=(tabNum!=0), d1=(tabNum!=1), d2=(tabNum!=2), d3=(tabNum!=3)
    GroupBox BCIGE_GB_sample,disable=d0
    Button BCIGE_prepare,disable=d0
    Button BCIGE_run,disable=d0
    Button BCIGE_input,disable=d0
    CheckBox BCIGE_keepPBP,disable=d0
    TitleBox BCIGE_timing1,disable=d0
    TitleBox BCIGE_timing2,disable=d0
    TitleBox BCIGE_timing3,disable=d0
    TitleBox BCIGE_timing4,disable=d0
    TitleBox BCIGE_fixed1,disable=d0
    TitleBox BCIGE_fixed2,disable=d0
    TitleBox BCIGE_warn1,disable=d0
    TitleBox BCIGE_warn2,disable=d0

    GroupBox BCIGE_GB_cal,disable=d1
    SetVariable BCIGE_aqfrac,disable=d1
    SetVariable BCIGE_bbhgeff,disable=d1
    SetVariable BCIGE_bhbleff,disable=d1
    SetVariable BCIGE_bbhgr2,disable=d1
    SetVariable BCIGE_bhblr2,disable=d1
    Button BCIGE_recal,disable=d1
    Button BCIGE_caltable,disable=d1
    Button BCIGE_calgraph,disable=d1
    TitleBox BCIGE_calnote1,disable=d1
    TitleBox BCIGE_calnote2,disable=d1
    TitleBox BCIGE_calnote3,disable=d1

    GroupBox BCIGE_GB_result,disable=d2
    Button BCIGE_results,disable=d2
    Button BCIGE_resgraph,disable=d2
    Button BCIGE_qctable,disable=d2
    SetVariable BCIGE_nstd,disable=d2
    SetVariable BCIGE_nlev,disable=d2
    SetVariable BCIGE_nblank,disable=d2
    SetVariable BCIGE_blankmean,disable=d2
    SetVariable BCIGE_blanksd,disable=d2
    TitleBox BCIGE_qcnote1,disable=d2
    TitleBox BCIGE_qcnote2,disable=d2
    TitleBox BCIGE_qcnote3,disable=d2
    TitleBox BCIGE_qcnote4,disable=d2

    GroupBox BCIGE_GB_particle,disable=d3
    SetVariable BCIGE_partrow,disable=d3
    SetVariable BCIGE_partbins,disable=d3
    Button BCIGE_partan,disable=d3
    Button BCIGE_partall,disable=d3
    Button BCIGE_partsummary,disable=d3
    Button BCIGE_partnumb,disable=d3
    Button BCIGE_partmass,disable=d3
    Button BCIGE_parttime,disable=d3
    Button BCIGE_partchan,disable=d3
    Button BCIGE_parttable,disable=d3
    TitleBox BCIGE_partnote1,disable=d3
    TitleBox BCIGE_partnote2,disable=d3
    TitleBox BCIGE_partnote3,disable=d3
    Return 0
End

Function BCIGE_PrepareBtn(ctrlName) : ButtonControl
    String ctrlName
    BCIGE_PrepareTimedTable()
    Return 0
End

Function BCIGE_PrepareTimedTable([BatchFldrFP,nSamples])
    String BatchFldrFP
    Variable nSamples
    BCIGE_Init()
    String savedDF=GetDataFolder(1)
    NVAR defLiq=root:BCIGE:DefaultLiqFlow
    NVAR defDrain=root:BCIGE:DefaultDrainFlow
    NVAR defPurge=root:BCIGE:DefaultPurgeFlow
    Variable promptIt=0
    if (ParamIsDefault(BatchFldrFP))
        BatchFldrFP="root:IceCores:YYYYMMDD_timed"
        promptIt=1
    endif
    if (ParamIsDefault(nSamples))
        nSamples=1
        promptIt=1
    endif
    if (promptIt)
        Prompt BatchFldrFP,"Full path for timed sample instructions/results:"
        Prompt nSamples,"Number of rows (standards + blanks + samples):"
        DoPrompt "IGE-UGA timed liquid samples",BatchFldrFP,nSamples
        if (V_flag)
            SetDataFolder $savedDF
            Return -1
        endif
    endif
    BatchFldrFP=QuoteLiberalPath(BatchFldrFP)
    CreateFoldersOfFullPath(BatchFldrFP,0)
    SetDataFolder $BatchFldrFP
    Make/O/T/N=(nSamples) FileDate="YYYYMMDD"
    Make/O/T/N=(nSamples) FileNumList=""
    Make/O/T/N=(nSamples) SampleID=""
    Make/O/T/N=(nSamples) StartTime="hh:mm:ss"
    Make/O/T/N=(nSamples) StopTime="hh:mm:ss"
    Make/O/N=(nSamples) TrimStart_s=0,TrimEnd_s=0
    Make/O/N=(nSamples) LiqSampleFlow=defLiq,LiqDrainFlow=defDrain,PurgeAirFlow=defPurge
    Note FileDate,"Required format YYYYMMDD"
    Note StartTime,"Measurement start time; required format hh:mm:ss"
    Note StopTime,"Measurement stop time; required format hh:mm:ss"
    Note TrimStart_s,"Explicit QC trim added to StartTime [s]; do not infer automatically from concentration"
    Note TrimEnd_s,"Explicit QC trim subtracted from StopTime [s]; do not infer automatically from concentration"
    Note LiqSampleFlow,"Liquid sample flow [ml/min]"
    Note LiqDrainFlow,"Liquid drain flow [ml/min]"
    Note PurgeAirFlow,"Purge air flow [l/min]"
    String/G BCIGE_TableVersion="SP2 IGE timed liquid workflow v2.1"
    String/G BCIGE_Calibration="IGE_BACON_20210222_DMA_AQ"
    SVAR last=root:BCIGE:LastBatchFldr
    last=BatchFldrFP
    DoWindow/K BCIGE_TimedInput
    Edit/N=BCIGE_TimedInput/W=(25,80,1180,430) FileDate,FileNumList,SampleID,StartTime,StopTime,TrimStart_s,TrimEnd_s,LiqSampleFlow,LiqDrainFlow,PurgeAirFlow
    ModifyTable width(FileDate)=85,width(FileNumList)=80,width(SampleID)=130,width(StartTime)=80,width(StopTime)=80
    ModifyTable width(TrimStart_s)=75,width(TrimEnd_s)=75,width(LiqSampleFlow)=85,width(LiqDrainFlow)=85,width(PurgeAirFlow)=85
    SetDataFolder $savedDF
    Return 0
End

Function BCIGE_ParseTime(FileDateStr,TimeStr)
    String FileDateStr,TimeStr
    if (strlen(FileDateStr)<8 || strlen(TimeStr)<8)
        return NaN
    endif
    Variable yy=str2num(FileDateStr[0,3])
    Variable mm=str2num(FileDateStr[4,5])
    Variable dd=str2num(FileDateStr[6,7])
    Variable hh=str2num(TimeStr[0,1])
    Variable mi=str2num(TimeStr[3,4])
    Variable ss=str2num(TimeStr[6,7])
    if (numtype(yy)!=0 || numtype(mm)!=0 || numtype(dd)!=0 || numtype(hh)!=0 || numtype(mi)!=0 || numtype(ss)!=0)
        return NaN
    endif
    if (hh<0 || hh>23 || mi<0 || mi>59 || ss<0 || ss>59)
        return NaN
    endif
    Variable d0=Date2Secs(yy,mm,dd)
    if (numtype(d0)!=0)
        return NaN
    endif
    return d0+hh*3600+mi*60+ss
End

Function BCIGE_StdNominal(SampleStr)
    String SampleStr
    if (StringMatch(SampleStr,"0.1 ppb") || StringMatch(SampleStr,"0.1ppb"))
        return 0.1
    elseif (StringMatch(SampleStr,"0.5 ppb") || StringMatch(SampleStr,"0.5ppb"))
        return 0.5
    elseif (StringMatch(SampleStr,"1 ppb") || StringMatch(SampleStr,"1ppb"))
        return 1
    elseif (StringMatch(SampleStr,"5 ppb") || StringMatch(SampleStr,"5ppb"))
        return 5
    elseif (StringMatch(SampleStr,"10 ppb") || StringMatch(SampleStr,"10ppb"))
        return 10
    elseif (StringMatch(SampleStr,"25 ppb") || StringMatch(SampleStr,"25ppb"))
        return 25
    elseif (StringMatch(SampleStr,"50 ppb") || StringMatch(SampleStr,"50ppb"))
        return 50
    elseif (StringMatch(SampleStr,"100 ppb") || StringMatch(SampleStr,"100ppb"))
        return 100
    endif
    return NaN
End

Function BCIGE_IsBlank(SampleStr)
    String SampleStr
    return StringMatch(SampleStr,"BLC*") || StringMatch(SampleStr,"BLANK*") || StringMatch(SampleStr,"Blank*") || StringMatch(SampleStr,"blank*")
End

Function BCIGE_RunBtn(ctrlName) : ButtonControl
    String ctrlName
    BCIGE_RunTimedAnalysis()
    Return 0
End

Function BCIGE_RunTimedAnalysis([BatchFldrFP,RawDataDir])
    String BatchFldrFP,RawDataDir
    BCIGE_Init()
    String savedDF=GetDataFolder(1)
    if (ParamIsDefault(BatchFldrFP))
        BatchFldrFP=BrowseForFolder("Select timed sample table folder:",StartPath=savedDF)
        if (StringMatch(BatchFldrFP,"cancelled"))
            Return -1
        endif
    endif
    if (ParamIsDefault(RawDataDir))
        NewPath/O/M="Select folder containing SP2 .sp2b raw data files"/Q BCIGE_RawPath
        if (V_flag!=0)
            Return -1
        endif
        PathInfo BCIGE_RawPath
        RawDataDir=ChopLastCharacterOff(S_path,":")
    endif
    SVAR lastRawDir=root:BCIGE:LastRawDataDir
    lastRawDir=RawDataDir
    BatchFldrFP=QuoteLiberalPath(BatchFldrFP)
    SetDataFolder $BatchFldrFP
    Wave/T DateStr=FileDate
    Wave/T FileListStr=FileNumList
    Wave/T SampleID
    Wave/T StartTime
    Wave/T StopTime
    Wave TrimStart_s,TrimEnd_s,LiqSampleFlow,LiqDrainFlow,PurgeAirFlow
    Variable nSamples=numpnts(DateStr)

    Make/O/T/N=(nSamples) SP2RawDataFP="",PBPDataFP="",QCFlag="PENDING"
    Make/O/D/N=(nSamples) TimeDateStart=NaN,TimeDateStop=NaN,TimeDateAvg=NaN
    SetScale d 0,0,"dat",TimeDateStart,TimeDateStop,TimeDateAvg
    Make/O/N=(nSamples) WindowSec=NaN,Ntriggers_Window=NaN
    Make/O/N=(nSamples) BBHG_Aerosol_ugm3=NaN,BHBL_Aerosol_ugm3=NaN
    Make/O/N=(nSamples) BBHG_LiquidSampleMassConc=NaN,BHBL_LiquidSampleMassConc=NaN
    Make/O/N=(nSamples) StdNominal_ppb=NaN,StdTarget_rBC_ppb=NaN
    Make/O/N=(nSamples) BBHG_BCcorr_ppb=NaN,BHBL_BCcorr_ppb=NaN
    Make/O/N=(nSamples) BBHG_BCcorrInt_ppb=NaN,BHBL_BCcorrInt_ppb=NaN
    Make/O/N=(nSamples) BBHG_Recovery_pct=NaN,BHBL_Recovery_pct=NaN
    Make/O/N=(nSamples) BBHG_Residual_ppb=NaN,BHBL_Residual_ppb=NaN

    NVAR AQfrac=root:BCIGE:AQ_rBC_fraction
    NVAR KeepPBP=root:BCIGE:KeepPBPData
    Variable i,j,t0,t1,conv,nom,futureUse
    String dateNow,fileNow,fileLoad,currRaw,currPBP,currConc,calibFP
    Variable reused
    calibFP="root:SP2toolkit:CalibData:IGE_BACON_20210222_DMA_AQ"

    for (i=0;i<nSamples;i+=1)
        nom=BCIGE_StdNominal(SampleID[i])
        StdNominal_ppb[i]=nom
        if (numtype(nom)==0)
            StdTarget_rBC_ppb[i]=nom*AQfrac
        endif
        t0=BCIGE_ParseTime(DateStr[i],StartTime[i])
        t1=BCIGE_ParseTime(DateStr[i],StopTime[i])
        if (numtype(t0)!=0 || numtype(t1)!=0)
            QCFlag[i]="INVALID_TIME_FORMAT"
            continue
        endif
        t0+=max(0,TrimStart_s[i])
        t1-=max(0,TrimEnd_s[i])
        if (t1<=t0)
            QCFlag[i]="INVALID_TIME_WINDOW"
            continue
        endif
        if ((LiqSampleFlow[i]-LiqDrainFlow[i])<=0 || PurgeAirFlow[i]<=0)
            QCFlag[i]="INVALID_FLOW"
            continue
        endif
        TimeDateStart[i]=t0
        TimeDateStop[i]=t1
        TimeDateAvg[i]=0.5*(t0+t1)
        WindowSec[i]=t1-t0

        reused=0
        for (j=0;j<i;j+=1)
            if (CmpStr(DateStr[j],DateStr[i])==0 && CmpStr(FileListStr[j],FileListStr[i])==0 && strlen(PBPDataFP[j])>0)
                currRaw=SP2RawDataFP[j]
                currPBP=PBPDataFP[j]
                SP2RawDataFP[i]=currRaw
                PBPDataFP[i]=currPBP
                reused=1
                break
            endif
        endfor

        if (!reused)
            dateNow=DateStr[i]
            fileNow=ReplaceString(",",FileListStr[i],";")
            currRaw=SP2_LoadRawData("",RawDataDir=RawDataDir,LoadType=3,FileDateString=dateNow,FileNumList=fileNow,ConcatMode=1,DelBits=65535,TAmode=1,PPmode=0,Omode=1)
            currRaw=ChopLastCharacterOff(currRaw,";")
            if (strlen(currRaw)==0)
                QCFlag[i]="RAW_LOAD_FAILED"
                continue
            endif
            currPBP=SP2_RawFldrFP2PBPfldrFP(currRaw)
            SP2RawDataFP[i]=currRaw
            PBPDataFP[i]=currPBP
            SP2_PBPpostprocessing(pbpfldrfp=currPBP,calibfldrfp=calibFP,PrintInfo=0,GraphMode=0)
        endif

        SP2_ConcTimeSeriesExtractor("",pbpfldrfp=currPBP,IntSec=-1,StartTime=t0,EndTime=t1,GraphMode=0)
        currConc=ChopLastCharacterOff(currPBP,":")+":ConcTser"
        SetDataFolder $currConc
        Wave/Z BBHG_MassConc
        Wave/Z BHBL_MassConc
        if (!WaveExists(BBHG_MassConc) && !WaveExists(BHBL_MassConc))
            SetDataFolder $BatchFldrFP
            QCFlag[i]="NO_CONCENTRATION_DATA"
            continue
        endif
        SetDataFolder $BatchFldrFP
        conv=PurgeAirFlow[i]/(LiqSampleFlow[i]-LiqDrainFlow[i])
        SetDataFolder $currConc
        Wave/Z BBHG_MassConc
        Wave/Z BHBL_MassConc
        if (WaveExists(BBHG_MassConc) && numpnts(BBHG_MassConc)>0)
            SetDataFolder $BatchFldrFP
            BBHG_Aerosol_ugm3[i]=BBHG_MassConc[0]
            BBHG_LiquidSampleMassConc[i]=BBHG_MassConc[0]*conv
        endif
        SetDataFolder $currConc
        Wave/Z BHBL_MassConc
        if (WaveExists(BHBL_MassConc) && numpnts(BHBL_MassConc)>0)
            SetDataFolder $BatchFldrFP
            BHBL_Aerosol_ugm3[i]=BHBL_MassConc[0]
            BHBL_LiquidSampleMassConc[i]=BHBL_MassConc[0]*conv
        endif

        SetDataFolder $currRaw
        Wave/Z TimeDate
        Variable nn=0,k
        if (WaveExists(TimeDate))
            for (k=0;k<numpnts(TimeDate);k+=1)
                if (TimeDate[k]>=t0 && TimeDate[k]<t1)
                    nn+=1
                endif
            endfor
        endif
        SetDataFolder $BatchFldrFP
        Ntriggers_Window[i]=nn
        if (nn==0)
            QCFlag[i]="NO_TRIGGERS_IN_WINDOW"
        else
            QCFlag[i]="OK"
        endif

        // Memory control: keep a file loaded only until its last timed window.
        futureUse=0
        for (j=i+1;j<nSamples;j+=1)
            if (CmpStr(DateStr[j],DateStr[i])==0 && CmpStr(FileListStr[j],FileListStr[i])==0)
                futureUse=1
                break
            endif
        endfor
        if (!KeepPBP && !futureUse)
            SetDataFolder root:
            KillDataFolder/Z $currPBP
            KillDataFolder/Z $currRaw
            SetDataFolder $BatchFldrFP
        endif
    endfor

    SVAR last=root:BCIGE:LastBatchFldr
    last=BatchFldrFP
    BCIGE_AutoCalibration(BatchFldrFP)
    BCIGE_OpenResults(BatchFldrFP)
    SetDataFolder $savedDF
    Print "SP2 IGE timed processing completed: "+BatchFldrFP
    Return 0
End


Function BCIGE_EnsureParticleSummary(BatchFldrFP)
    String BatchFldrFP
    String savedDF=GetDataFolder(1)
    if (!DataFolderExists(BatchFldrFP))
        return -1
    endif
    SetDataFolder $BatchFldrFP
    Wave/T SampleID
    Variable n=numpnts(SampleID)
    if (exists("ParticleQCFlag")!=1)
        Make/O/T/N=(n) ParticleQCFlag="NOT_ANALYZED"
    else
        Redimension/N=(n) ParticleQCFlag
    endif
    if (exists("ParticleFolderFP")!=1)
        Make/O/T/N=(n) ParticleFolderFP=""
    else
        Redimension/N=(n) ParticleFolderFP
    endif
    if (exists("Particle_Ntriggers")!=1)
        Make/O/N=(n) Particle_Ntriggers=NaN
        Make/O/N=(n) Particle_TriggerRate_Hz=NaN
        Make/O/N=(n) BHBL_Nparticles=NaN,BBHG_Nparticles=NaN
        Make/O/N=(n) BHBL_MeanMass_fg=NaN,BHBL_MedianMass_fg=NaN
        Make/O/N=(n) BHBL_D10N_nm=NaN,BHBL_D50N_nm=NaN,BHBL_D90N_nm=NaN
        Make/O/N=(n) BHBL_D10M_nm=NaN,BHBL_D50M_nm=NaN,BHBL_D90M_nm=NaN
        Make/O/N=(n) BBHG_D50N_nm=NaN,BBHG_D50M_nm=NaN
        Make/O/N=(n) BBHG_SatAll_pct=NaN,BBLG_SatAll_pct=NaN,BHBL_SatAll_pct=NaN
    else
        Redimension/N=(n) Particle_Ntriggers,Particle_TriggerRate_Hz
        Redimension/N=(n) BHBL_Nparticles,BBHG_Nparticles
        Redimension/N=(n) BHBL_MeanMass_fg,BHBL_MedianMass_fg
        Redimension/N=(n) BHBL_D10N_nm,BHBL_D50N_nm,BHBL_D90N_nm
        Redimension/N=(n) BHBL_D10M_nm,BHBL_D50M_nm,BHBL_D90M_nm
        Redimension/N=(n) BBHG_D50N_nm,BBHG_D50M_nm
        Redimension/N=(n) BBHG_SatAll_pct,BBLG_SatAll_pct,BHBL_SatAll_pct
    endif
    SetDataFolder $savedDF
    return 0
End

Function/S BCIGE_ParticleRowFolder(BatchFldrFP,row)
    String BatchFldrFP
    Variable row
    String base=ChopLastCharacterOff(BatchFldrFP,":")+":ParticleProps"
    return base+":Row"+num2istr(row)
End

Function BCIGE_WeightedQuantile(X,W,qval)
    Wave X,W
    Variable qval
    Variable n=numpnts(X),i,total=0,cum=0
    if (n<1 || numpnts(W)!=n)
        return NaN
    endif
    Duplicate/FREE X,Xsort
    Duplicate/FREE W,Wsort
    Sort Xsort,Xsort,Wsort
    for (i=0;i<n;i+=1)
        if (numtype(Xsort[i])==0 && numtype(Wsort[i])==0 && Wsort[i]>0)
            total+=Wsort[i]
        endif
    endfor
    if (total<=0)
        return NaN
    endif
    qval=max(0,min(1,qval))
    for (i=0;i<n;i+=1)
        if (numtype(Xsort[i])==0 && numtype(Wsort[i])==0 && Wsort[i]>0)
            cum+=Wsort[i]
            if (cum>=qval*total)
                return Xsort[i]
            endif
        endif
    endfor
    return NaN
End

Function BCIGE_AnalyzeParticleRow(BatchFldrFP,row)
    String BatchFldrFP
    Variable row
    BCIGE_Init()
    String savedDF=GetDataFolder(1)
    row=round(row)
    if (!DataFolderExists(BatchFldrFP))
        Print "Particle analysis: batch folder not found."
        return -1
    endif
    BCIGE_EnsureParticleSummary(BatchFldrFP)
    SetDataFolder $BatchFldrFP
    Wave/T FileDate,FileNumList,SampleID,StartTime,StopTime,ParticleQCFlag,ParticleFolderFP
    Wave TrimStart_s,TrimEnd_s,LiqSampleFlow,LiqDrainFlow,PurgeAirFlow
    Wave Particle_Ntriggers,Particle_TriggerRate_Hz,BHBL_Nparticles,BBHG_Nparticles
    Wave BHBL_MeanMass_fg,BHBL_MedianMass_fg
    Wave BHBL_D10N_nm,BHBL_D50N_nm,BHBL_D90N_nm,BHBL_D10M_nm,BHBL_D50M_nm,BHBL_D90M_nm
    Wave BBHG_D50N_nm,BBHG_D50M_nm,BBHG_SatAll_pct,BBLG_SatAll_pct,BHBL_SatAll_pct
    Variable nrows=numpnts(SampleID)
    if (row<0 || row>=nrows)
        Print "Particle analysis: invalid row."
        SetDataFolder $savedDF
        return -1
    endif

    Variable t0=BCIGE_ParseTime(FileDate[row],StartTime[row])
    Variable t1=BCIGE_ParseTime(FileDate[row],StopTime[row])
    if (numtype(t0)!=0 || numtype(t1)!=0)
        ParticleQCFlag[row]="INVALID_TIME_FORMAT"
        SetDataFolder $savedDF
        return -1
    endif
    t0+=max(0,TrimStart_s[row])
    t1-=max(0,TrimEnd_s[row])
    if (t1<=t0)
        ParticleQCFlag[row]="INVALID_TIME_WINDOW"
        SetDataFolder $savedDF
        return -1
    endif
    if ((LiqSampleFlow[row]-LiqDrainFlow[row])<=0 || PurgeAirFlow[row]<=0)
        ParticleQCFlag[row]="INVALID_FLOW"
        SetDataFolder $savedDF
        return -1
    endif

    String rawFP="",pbpFP="",rawDir="",fileNow,calibFP
    Variable loadedTemp=0
    Wave/T/Z SP2RawDataFP,PBPDataFP
    if (WaveExists(PBPDataFP) && WaveExists(SP2RawDataFP))
        if (strlen(PBPDataFP[row])>0 && DataFolderExists(PBPDataFP[row]))
            pbpFP=PBPDataFP[row]
            rawFP=SP2RawDataFP[row]
        endif
    endif

    if (strlen(pbpFP)==0)
        SVAR lastRaw=root:BCIGE:LastRawDataDir
        rawDir=lastRaw
        if (strlen(rawDir)==0)
            NewPath/O/M="Select folder containing SP2 .sp2b raw data files"/Q BCIGE_ParticleRawPath
            if (V_flag!=0)
                ParticleQCFlag[row]="RAW_FOLDER_CANCELLED"
                SetDataFolder $savedDF
                return -1
            endif
            PathInfo BCIGE_ParticleRawPath
            rawDir=ChopLastCharacterOff(S_path,":")
            lastRaw=rawDir
        endif
        fileNow=ReplaceString(",",FileNumList[row],";")
        rawFP=SP2_LoadRawData("",RawDataDir=rawDir,LoadType=3,FileDateString=FileDate[row],FileNumList=fileNow,ConcatMode=1,DelBits=65535,TAmode=1,PPmode=0,Omode=1)
        rawFP=ChopLastCharacterOff(rawFP,";")
        if (strlen(rawFP)==0)
            ParticleQCFlag[row]="RAW_LOAD_FAILED"
            SetDataFolder $savedDF
            return -1
        endif
        pbpFP=SP2_RawFldrFP2PBPfldrFP(rawFP)
        calibFP="root:SP2toolkit:CalibData:IGE_BACON_20210222_DMA_AQ"
        SP2_PBPpostprocessing(pbpfldrfp=pbpFP,calibfldrfp=calibFP,PrintInfo=0,GraphMode=0)
        loadedTemp=1
    endif

    if (!DataFolderExists(rawFP) || !DataFolderExists(pbpFP))
        ParticleQCFlag[row]="PBP_NOT_AVAILABLE"
        SetDataFolder $savedDF
        return -1
    endif

    SetDataFolder $rawFP
    Wave/Z TimeDate
    if (!WaveExists(TimeDate))
        SetDataFolder $BatchFldrFP
        ParticleQCFlag[row]="NO_TIMEDATE"
        SetDataFolder $savedDF
        return -1
    endif

    SetDataFolder $pbpFP
    Wave/Z BHBLmass=BHBL_BCmass
    Wave/Z BHBLdiam=BHBL_BCdiam
    Wave/Z BBHGmass=BBHG_BCmass
    Wave/Z BBHGdiam=BBHG_BCdiam
    Wave/Z BBHGsat=BBHG_saturated
    Wave/Z BBLGsat=BBLG_saturated
    Wave/Z BHBLsat=BHBL_saturated

    Variable i,nTime=numpnts(TimeDate),nTrig=0,nBH=0,nBG=0
    Variable satHG=0,satLG=0,satBoth=0,nCommon
    for (i=0;i<nTime;i+=1)
        if (TimeDate[i]>=t0 && TimeDate[i]<t1)
            nTrig+=1
        endif
    endfor
    SetDataFolder $BatchFldrFP
    Particle_Ntriggers[row]=nTrig
    Particle_TriggerRate_Hz[row]=nTrig/(t1-t0)
    if (nTrig<=0)
        ParticleQCFlag[row]="NO_TRIGGERS_IN_WINDOW"
        SetDataFolder $savedDF
        return -1
    endif

    if (WaveExists(BHBLmass) && WaveExists(BHBLdiam))
        nCommon=min(nTime,numpnts(BHBLmass))
        nCommon=min(nCommon,numpnts(BHBLdiam))
        for (i=0;i<nCommon;i+=1)
            if (TimeDate[i]>=t0 && TimeDate[i]<t1)
                if (numtype(BHBLmass[i])==0 && numtype(BHBLdiam[i])==0 && BHBLdiam[i]>0)
                    nBH+=1
                endif
            endif
        endfor
    endif
    if (WaveExists(BBHGmass) && WaveExists(BBHGdiam))
        nCommon=min(nTime,numpnts(BBHGmass))
        nCommon=min(nCommon,numpnts(BBHGdiam))
        for (i=0;i<nCommon;i+=1)
            if (TimeDate[i]>=t0 && TimeDate[i]<t1)
                if (numtype(BBHGmass[i])==0 && numtype(BBHGdiam[i])==0 && BBHGdiam[i]>0)
                    nBG+=1
                endif
            endif
        endfor
    endif

    if (WaveExists(BBHGsat))
        nCommon=min(nTime,numpnts(BBHGsat))
        for (i=0;i<nCommon;i+=1)
            if (TimeDate[i]>=t0 && TimeDate[i]<t1 && BBHGsat[i]!=0)
                satHG+=1
            endif
        endfor
    endif
    if (WaveExists(BBLGsat))
        nCommon=min(nTime,numpnts(BBLGsat))
        for (i=0;i<nCommon;i+=1)
            if (TimeDate[i]>=t0 && TimeDate[i]<t1 && BBLGsat[i]!=0)
                satLG+=1
            endif
        endfor
    endif
    if (WaveExists(BHBLsat))
        nCommon=min(nTime,numpnts(BHBLsat))
        for (i=0;i<nCommon;i+=1)
            if (TimeDate[i]>=t0 && TimeDate[i]<t1 && BHBLsat[i]!=0)
                satBoth+=1
            endif
        endfor
    endif

    SetDataFolder $BatchFldrFP
    BHBL_Nparticles[row]=nBH
    BBHG_Nparticles[row]=nBG
    BBHG_SatAll_pct[row]=100*satHG/nTrig
    BBLG_SatAll_pct[row]=100*satLG/nTrig
    BHBL_SatAll_pct[row]=100*satBoth/nTrig

    String rowFldr=BCIGE_ParticleRowFolder(BatchFldrFP,row)
    CreateFoldersOfFullPath(rowFldr,0)
    ParticleFolderFP[row]=rowFldr
    SetDataFolder $rowFldr
    String/G SampleID_value=SampleID[row]
    Variable/G WindowStart=t0
    Variable/G WindowStop=t1

    if (nBH>0)
        Make/FREE/N=(nBH) bhMass=NaN,bhDiam=NaN
        Variable q=0
        nCommon=min(nTime,numpnts(BHBLmass))
        nCommon=min(nCommon,numpnts(BHBLdiam))
        for (i=0;i<nCommon;i+=1)
            if (TimeDate[i]>=t0 && TimeDate[i]<t1)
                if (numtype(BHBLmass[i])==0 && numtype(BHBLdiam[i])==0 && BHBLdiam[i]>0)
                    bhMass[q]=BHBLmass[i]
                    bhDiam[q]=BHBLdiam[i]
                    q+=1
                endif
            endif
        endfor
        WaveStats/Q bhMass
        SetDataFolder $BatchFldrFP
        BHBL_MeanMass_fg[row]=V_avg
        BHBL_MedianMass_fg[row]=Percentile_of_ListNaN(bhMass,0.5)
        BHBL_D10N_nm[row]=Percentile_of_ListNaN(bhDiam,0.1)
        BHBL_D50N_nm[row]=Percentile_of_ListNaN(bhDiam,0.5)
        BHBL_D90N_nm[row]=Percentile_of_ListNaN(bhDiam,0.9)
        BHBL_D10M_nm[row]=BCIGE_WeightedQuantile(bhDiam,bhMass,0.1)
        BHBL_D50M_nm[row]=BCIGE_WeightedQuantile(bhDiam,bhMass,0.5)
        BHBL_D90M_nm[row]=BCIGE_WeightedQuantile(bhDiam,bhMass,0.9)
    endif

    if (nBG>0)
        Make/FREE/N=(nBG) bgMass=NaN,bgDiam=NaN
        q=0
        nCommon=min(nTime,numpnts(BBHGmass))
        nCommon=min(nCommon,numpnts(BBHGdiam))
        for (i=0;i<nCommon;i+=1)
            if (TimeDate[i]>=t0 && TimeDate[i]<t1)
                if (numtype(BBHGmass[i])==0 && numtype(BBHGdiam[i])==0 && BBHGdiam[i]>0)
                    bgMass[q]=BBHGmass[i]
                    bgDiam[q]=BBHGdiam[i]
                    q+=1
                endif
            endif
        endfor
        SetDataFolder $BatchFldrFP
        BBHG_D50N_nm[row]=Percentile_of_ListNaN(bgDiam,0.5)
        BBHG_D50M_nm[row]=BCIGE_WeightedQuantile(bgDiam,bgMass,0.5)
    endif

    NVAR maxPlot=root:BCIGE:ParticleMaxPlotPoints
    Variable stride=1,nSave=0,winIndex=0,saveIndex=0
    if (nTrig>maxPlot && maxPlot>0)
        stride=ceil(nTrig/maxPlot)
    endif
    nSave=ceil(nTrig/stride)
    SetDataFolder $rowFldr
    Make/O/D/N=(nSave) PlotTime_s=NaN
    Make/O/N=(nSave) Plot_BHBL_Mass_fg=NaN,Plot_BHBL_Diam_nm=NaN
    Make/O/N=(nSave) Plot_BBHG_Mass_fg=NaN,Plot_BBHG_Diam_nm=NaN
    nCommon=nTime
    for (i=0;i<nCommon;i+=1)
        if (TimeDate[i]>=t0 && TimeDate[i]<t1)
            if (mod(winIndex,stride)==0 && saveIndex<nSave)
                PlotTime_s[saveIndex]=TimeDate[i]-t0
                if (WaveExists(BHBLmass) && i<numpnts(BHBLmass))
                    Plot_BHBL_Mass_fg[saveIndex]=BHBLmass[i]
                endif
                if (WaveExists(BHBLdiam) && i<numpnts(BHBLdiam))
                    Plot_BHBL_Diam_nm[saveIndex]=BHBLdiam[i]
                endif
                if (WaveExists(BBHGmass) && i<numpnts(BBHGmass))
                    Plot_BBHG_Mass_fg[saveIndex]=BBHGmass[i]
                endif
                if (WaveExists(BBHGdiam) && i<numpnts(BBHGdiam))
                    Plot_BBHG_Diam_nm[saveIndex]=BBHGdiam[i]
                endif
                saveIndex+=1
            endif
            winIndex+=1
        endif
    endfor

    NVAR nBins=root:BCIGE:ParticleSizeBins
    nBins=round(max(20,min(200,nBins)))
    SP2_SizeDistTimeSeriesExtractor("",pbpfldrfp=pbpFP,IntSec=-1,StartTime=t0,EndTime=t1,nSizeBins=nBins,FitLogNorm=0,MakeGraph=0)
    String sdFldr=ChopLastCharacterOff(pbpFP,":")+":SizeDistTser"
    Variable sizeOK=0
    if (DataFolderExists(sdFldr))
        SetDataFolder $sdFldr
        Wave/Z bhD=BHBL_DiamMidpt
        Wave/Z bhN=BHBL_NumbDistr
        Wave/Z bhM=BHBL_MassDistr
        Wave/Z bgD=BBHG_DiamMidpt
        Wave/Z bgN=BBHG_NumbDistr
        Wave/Z bgM=BBHG_MassDistr
        SetDataFolder $rowFldr
        Variable jj,nout
        if (WaveExists(bhD) && WaveExists(bhN) && WaveExists(bhM))
            nout=numpnts(bhD)
            Make/O/N=(nout) BHBL_Diam_nm=NaN,BHBL_dNdlogDp_cm3=NaN,BHBL_dMdlogDp_ugm3=NaN
            for (jj=0;jj<nout;jj+=1)
                BHBL_Diam_nm[jj]=bhD[jj]
                if (dimsize(bhN,0)>0 && dimsize(bhN,1)>jj)
                    BHBL_dNdlogDp_cm3[jj]=bhN[0][jj]
                endif
                if (dimsize(bhM,0)>0 && dimsize(bhM,1)>jj)
                    BHBL_dMdlogDp_ugm3[jj]=bhM[0][jj]
                endif
            endfor
            sizeOK=1
        endif
        if (WaveExists(bgD) && WaveExists(bgN) && WaveExists(bgM))
            nout=numpnts(bgD)
            Make/O/N=(nout) BBHG_Diam_nm=NaN,BBHG_dNdlogDp_cm3=NaN,BBHG_dMdlogDp_ugm3=NaN
            for (jj=0;jj<nout;jj+=1)
                BBHG_Diam_nm[jj]=bgD[jj]
                if (dimsize(bgN,0)>0 && dimsize(bgN,1)>jj)
                    BBHG_dNdlogDp_cm3[jj]=bgN[0][jj]
                endif
                if (dimsize(bgM,0)>0 && dimsize(bgM,1)>jj)
                    BBHG_dMdlogDp_ugm3[jj]=bgM[0][jj]
                endif
            endfor
        endif
    endif

    SetDataFolder $BatchFldrFP
    if (nBH<=0)
        ParticleQCFlag[row]="NO_BHBL_PARTICLES"
    elseif (!sizeOK)
        ParticleQCFlag[row]="SIZE_DIST_MISSING"
    else
        ParticleQCFlag[row]="OK"
    endif
    SVAR pstat=root:BCIGE:ParticleStatus
    pstat="Row "+num2istr(row)+": "+ParticleQCFlag[row]
    Print "Particle analysis | row="+num2istr(row)+" | "+SampleID[row]+" | "+ParticleQCFlag[row]

    NVAR keepPBP=root:BCIGE:KeepPBPData
    if (loadedTemp && !keepPBP)
        SetDataFolder root:
        KillDataFolder/Z $pbpFP
        KillDataFolder/Z $rawFP
    endif
    SetDataFolder $savedDF
    return 0
End

Function BCIGE_ParticleAnalyzeBtn(ctrlName) : ButtonControl
    String ctrlName
    NVAR row=root:BCIGE:ParticleRow
    SVAR last=root:BCIGE:LastBatchFldr
    if (strlen(last)==0)
        Print "No timed batch selected."
        return -1
    endif
    BCIGE_AnalyzeParticleRow(last,row)
    Return 0
End

Function BCIGE_ParticleAnalyzeAllBtn(ctrlName) : ButtonControl
    String ctrlName
    SVAR last=root:BCIGE:LastBatchFldr
    if (strlen(last)==0 || !DataFolderExists(last))
        Print "No timed batch selected."
        return -1
    endif
    String savedDF=GetDataFolder(1)
    SetDataFolder $last
    Wave/T SampleID
    Variable i,n=numpnts(SampleID)
    SetDataFolder $savedDF
    for (i=0;i<n;i+=1)
        BCIGE_AnalyzeParticleRow(last,i)
    endfor
    Print "Particle analysis completed for "+num2istr(n)+" rows."
    Return 0
End

Function BCIGE_ParticleSummaryBtn(ctrlName) : ButtonControl
    String ctrlName
    SVAR last=root:BCIGE:LastBatchFldr
    if (strlen(last)==0 || !DataFolderExists(last))
        return -1
    endif
    BCIGE_EnsureParticleSummary(last)
    String savedDF=GetDataFolder(1)
    SetDataFolder $last
    Wave/T SampleID,ParticleQCFlag
    Wave Particle_Ntriggers,Particle_TriggerRate_Hz,BHBL_Nparticles,BBHG_Nparticles
    Wave BHBL_MeanMass_fg,BHBL_MedianMass_fg
    Wave BHBL_D10N_nm,BHBL_D50N_nm,BHBL_D90N_nm,BHBL_D10M_nm,BHBL_D50M_nm,BHBL_D90M_nm
    Wave BBHG_D50N_nm,BBHG_D50M_nm,BBHG_SatAll_pct,BBLG_SatAll_pct,BHBL_SatAll_pct
    DoWindow/K BCIGE_ParticleSummary
    Edit/N=BCIGE_ParticleSummary/W=(20,70,1480,620) SampleID,Particle_Ntriggers,Particle_TriggerRate_Hz,BHBL_Nparticles,BBHG_Nparticles,BHBL_MeanMass_fg,BHBL_MedianMass_fg,BHBL_D10N_nm,BHBL_D50N_nm,BHBL_D90N_nm,BHBL_D10M_nm,BHBL_D50M_nm,BHBL_D90M_nm,BBHG_D50N_nm,BBHG_D50M_nm,BBHG_SatAll_pct,BBLG_SatAll_pct,BHBL_SatAll_pct,ParticleQCFlag
    SetDataFolder $savedDF
    Return 0
End

Function BCIGE_GetParticleRowFolder(rowFldr)
    String &rowFldr
    NVAR row=root:BCIGE:ParticleRow
    SVAR last=root:BCIGE:LastBatchFldr
    if (strlen(last)==0 || !DataFolderExists(last))
        return 0
    endif
    rowFldr=BCIGE_ParticleRowFolder(last,round(row))
    if (!DataFolderExists(rowFldr))
        Print "Analyze the selected particle row first."
        return 0
    endif
    return 1
End

Function BCIGE_ParticleNumbGraphBtn(ctrlName) : ButtonControl
    String ctrlName
    String rowFldr=""
    if (!BCIGE_GetParticleRowFolder(rowFldr))
        return -1
    endif
    String savedDF=GetDataFolder(1)
    SetDataFolder $rowFldr
    Wave/Z BHBL_Diam_nm,BHBL_dNdlogDp_cm3,BBHG_Diam_nm,BBHG_dNdlogDp_cm3
    if (!WaveExists(BHBL_Diam_nm) || !WaveExists(BHBL_dNdlogDp_cm3))
        SetDataFolder $savedDF
        return -1
    endif
    DoWindow/K BCIGE_NumbSize
    Display/N=BCIGE_NumbSize/W=(80,80,820,540) BHBL_dNdlogDp_cm3 vs BHBL_Diam_nm
    if (WaveExists(BBHG_Diam_nm) && WaveExists(BBHG_dNdlogDp_cm3))
        AppendToGraph BBHG_dNdlogDp_cm3 vs BBHG_Diam_nm
    endif
    ModifyGraph log(bottom)=1
    Label bottom "rBC mass-equivalent diameter [nm]"
    Label left "dN/dlogDp [#/cm3]"
    SetDataFolder $savedDF
    Return 0
End

Function BCIGE_ParticleMassGraphBtn(ctrlName) : ButtonControl
    String ctrlName
    String rowFldr=""
    if (!BCIGE_GetParticleRowFolder(rowFldr))
        return -1
    endif
    String savedDF=GetDataFolder(1)
    SetDataFolder $rowFldr
    Wave/Z BHBL_Diam_nm,BHBL_dMdlogDp_ugm3,BBHG_Diam_nm,BBHG_dMdlogDp_ugm3
    if (!WaveExists(BHBL_Diam_nm) || !WaveExists(BHBL_dMdlogDp_ugm3))
        SetDataFolder $savedDF
        return -1
    endif
    DoWindow/K BCIGE_MassSize
    Display/N=BCIGE_MassSize/W=(100,100,840,560) BHBL_dMdlogDp_ugm3 vs BHBL_Diam_nm
    if (WaveExists(BBHG_Diam_nm) && WaveExists(BBHG_dMdlogDp_ugm3))
        AppendToGraph BBHG_dMdlogDp_ugm3 vs BBHG_Diam_nm
    endif
    ModifyGraph log(bottom)=1
    Label bottom "rBC mass-equivalent diameter [nm]"
    Label left "dM/dlogDp [ug/m3]"
    SetDataFolder $savedDF
    Return 0
End

Function BCIGE_ParticleTimeGraphBtn(ctrlName) : ButtonControl
    String ctrlName
    String rowFldr=""
    if (!BCIGE_GetParticleRowFolder(rowFldr))
        return -1
    endif
    String savedDF=GetDataFolder(1)
    SetDataFolder $rowFldr
    Wave/Z PlotTime_s,Plot_BHBL_Mass_fg,Plot_BHBL_Diam_nm
    if (!WaveExists(PlotTime_s) || !WaveExists(Plot_BHBL_Mass_fg))
        SetDataFolder $savedDF
        return -1
    endif
    DoWindow/K BCIGE_ParticleMassTime
    Display/N=BCIGE_ParticleMassTime/W=(120,90,850,500) Plot_BHBL_Mass_fg vs PlotTime_s
    Label bottom "Seconds from effective StartTime"
    Label left "Single-particle rBC mass [fg]"
    if (WaveExists(Plot_BHBL_Diam_nm))
        DoWindow/K BCIGE_ParticleDiamTime
        Display/N=BCIGE_ParticleDiamTime/W=(160,130,890,540) Plot_BHBL_Diam_nm vs PlotTime_s
        Label bottom "Seconds from effective StartTime"
        Label left "rBC mass-equivalent diameter [nm]"
    endif
    SetDataFolder $savedDF
    Return 0
End

Function BCIGE_ParticleChannelGraphBtn(ctrlName) : ButtonControl
    String ctrlName
    String rowFldr=""
    if (!BCIGE_GetParticleRowFolder(rowFldr))
        return -1
    endif
    String savedDF=GetDataFolder(1)
    SetDataFolder $rowFldr
    Wave/Z Plot_BBHG_Mass_fg,Plot_BHBL_Mass_fg
    if (!WaveExists(Plot_BBHG_Mass_fg) || !WaveExists(Plot_BHBL_Mass_fg))
        SetDataFolder $savedDF
        return -1
    endif
    DoWindow/K BCIGE_BBHGvsBHBL
    Display/N=BCIGE_BBHGvsBHBL/W=(130,90,830,540) Plot_BHBL_Mass_fg vs Plot_BBHG_Mass_fg
    ModifyGraph mode=3,marker=19
    Label bottom "BBHG single-particle rBC mass [fg]"
    Label left "BHBL single-particle rBC mass [fg]"
    SetDataFolder $savedDF
    Return 0
End

Function BCIGE_ParticleDetailBtn(ctrlName) : ButtonControl
    String ctrlName
    String rowFldr=""
    if (!BCIGE_GetParticleRowFolder(rowFldr))
        return -1
    endif
    String savedDF=GetDataFolder(1)
    SetDataFolder $rowFldr
    Wave/Z PlotTime_s,Plot_BHBL_Mass_fg,Plot_BHBL_Diam_nm,Plot_BBHG_Mass_fg,Plot_BBHG_Diam_nm
    if (!WaveExists(PlotTime_s))
        SetDataFolder $savedDF
        return -1
    endif
    DoWindow/K BCIGE_ParticleDetail
    Edit/N=BCIGE_ParticleDetail/W=(60,90,1050,560) PlotTime_s,Plot_BHBL_Mass_fg,Plot_BHBL_Diam_nm,Plot_BBHG_Mass_fg,Plot_BBHG_Diam_nm
    SetDataFolder $savedDF
    Return 0
End

Function BCIGE_OLS(X,Y,n,slope,intercept,r2)
    Wave X,Y
    Variable n
    Variable &slope,&intercept,&r2
    Variable i,nn=0,sx=0,sy=0,sxx=0,sxy=0,ssTot=0,ssRes=0,xb,yb,pred
    for (i=0;i<n;i+=1)
        if (numtype(X[i])==0 && numtype(Y[i])==0)
            nn+=1
            sx+=X[i]
            sy+=Y[i]
            sxx+=X[i]*X[i]
            sxy+=X[i]*Y[i]
        endif
    endfor
    if (nn<2 || (nn*sxx-sx*sx)==0)
        slope=NaN
        intercept=NaN
        r2=NaN
        return 0
    endif
    slope=(nn*sxy-sx*sy)/(nn*sxx-sx*sx)
    intercept=(sy-slope*sx)/nn
    yb=sy/nn
    for (i=0;i<n;i+=1)
        if (numtype(X[i])==0 && numtype(Y[i])==0)
            pred=intercept+slope*X[i]
            ssTot+=(Y[i]-yb)^2
            ssRes+=(Y[i]-pred)^2
        endif
    endfor
    if (ssTot>0)
        r2=1-ssRes/ssTot
    else
        r2=NaN
    endif
    return nn
End

Function BCIGE_AutoCalibration(BatchFldrFP)
    String BatchFldrFP
    String savedDF=GetDataFolder(1)
    SetDataFolder $BatchFldrFP
    Wave/T SampleID,QCFlag
    Wave StdNominal_ppb,StdTarget_rBC_ppb
    Wave BBHG_LiquidSampleMassConc,BHBL_LiquidSampleMassConc
    Wave BBHG_BCcorr_ppb,BHBL_BCcorr_ppb,BBHG_BCcorrInt_ppb,BHBL_BCcorrInt_ppb
    Wave BBHG_Recovery_pct,BHBL_Recovery_pct,BBHG_Residual_ppb,BHBL_Residual_ppb
    Variable n=numpnts(StdNominal_ppb),i,k,nStd=0
    for (i=0;i<n;i+=1)
        if (numtype(StdNominal_ppb[i])==0 && StdNominal_ppb[i]>0)
            nStd+=1
        endif
    endfor
    if (nStd<3)
        SVAR stat0=root:BCIGE:CalStatus
        stat0="FAILED: fewer than 3 valid AquaDAG standards"
        SetDataFolder $savedDF
        return -1
    endif

    Make/O/N=(nStd) CalNominal_ppb=NaN,CalTarget_rBC_ppb=NaN
    Make/O/N=(nStd) Cal_BBHG_raw=NaN,Cal_BHBL_raw=NaN
    k=0
    for (i=0;i<n;i+=1)
        if (numtype(StdNominal_ppb[i])==0 && StdNominal_ppb[i]>0)
            CalNominal_ppb[k]=StdNominal_ppb[i]
            CalTarget_rBC_ppb[k]=StdTarget_rBC_ppb[i]
            Cal_BBHG_raw[k]=BBHG_LiquidSampleMassConc[i]
            Cal_BHBL_raw[k]=BHBL_LiquidSampleMassConc[i]
            k+=1
        endif
    endfor

    Variable sB,iB,rB,sH,iH,rH,nC,nH
    nC=BCIGE_OLS(CalNominal_ppb,Cal_BBHG_raw,nStd,sB,iB,rB)
    nH=BCIGE_OLS(CalNominal_ppb,Cal_BHBL_raw,nStd,sH,iH,rH)
    NVAR AQfrac=root:BCIGE:AQ_rBC_fraction
    Variable eB=sB/AQfrac,eH=sH/AQfrac

    Variable/G BBHG_CalSlope=sB,BBHG_CalIntercept=iB,BBHG_CalR2=rB,BBHG_Efficiency=eB
    Variable/G BHBL_CalSlope=sH,BHBL_CalIntercept=iH,BHBL_CalR2=rH,BHBL_Efficiency=eH
    Variable/G AquaDAG_rBC_fraction=AQfrac
    Variable/G Nstandards_used=min(nC,nH)

    NVAR g_sB=root:BCIGE:BBHG_slope
    g_sB=sB
    NVAR g_sH=root:BCIGE:BHBL_slope
    g_sH=sH
    NVAR g_iB=root:BCIGE:BBHG_intercept
    g_iB=iB
    NVAR g_iH=root:BCIGE:BHBL_intercept
    g_iH=iH
    NVAR g_rB=root:BCIGE:BBHG_R2
    g_rB=rB
    NVAR g_rH=root:BCIGE:BHBL_R2
    g_rH=rH
    NVAR g_eB=root:BCIGE:BBHG_efficiency
    g_eB=eB
    NVAR g_eH=root:BCIGE:BHBL_efficiency
    g_eH=eH
    NVAR g_ns=root:BCIGE:Nstandards
    g_ns=nStd

    Variable nlev=0
    Variable h01=0,h05=0,h1=0,h5=0,h10=0,h25=0,h50=0,h100=0
    for (i=0;i<nStd;i+=1)
        if (CalNominal_ppb[i]==0.1)
            h01=1
        endif
        if (CalNominal_ppb[i]==0.5)
            h05=1
        endif
        if (CalNominal_ppb[i]==1)
            h1=1
        endif
        if (CalNominal_ppb[i]==5)
            h5=1
        endif
        if (CalNominal_ppb[i]==10)
            h10=1
        endif
        if (CalNominal_ppb[i]==25)
            h25=1
        endif
        if (CalNominal_ppb[i]==50)
            h50=1
        endif
        if (CalNominal_ppb[i]==100)
            h100=1
        endif
    endfor
    nlev=h01+h05+h1+h5+h10+h25+h50+h100
    NVAR g_nl=root:BCIGE:Nlevels
    g_nl=nlev

    Make/O/N=(nStd) Cal_BBHG_corr=NaN,Cal_BHBL_corr=NaN
    Make/O/N=(nStd) Cal_BBHG_resid=NaN,Cal_BHBL_resid=NaN
    Make/O/N=(nStd) Cal_BBHG_recovery=NaN,Cal_BHBL_recovery=NaN
    if (numtype(eB)==0 && eB>0)
        Cal_BBHG_corr=Cal_BBHG_raw/eB
        Cal_BBHG_resid=Cal_BBHG_corr-CalTarget_rBC_ppb
        Cal_BBHG_recovery=100*Cal_BBHG_corr/CalTarget_rBC_ppb
    endif
    if (numtype(eH)==0 && eH>0)
        Cal_BHBL_corr=Cal_BHBL_raw/eH
        Cal_BHBL_resid=Cal_BHBL_corr-CalTarget_rBC_ppb
        Cal_BHBL_recovery=100*Cal_BHBL_corr/CalTarget_rBC_ppb
    endif

    Variable badBBHG,badBHBL
    for (i=0;i<n;i+=1)
        if (numtype(eB)==0 && eB>0 && numtype(BBHG_LiquidSampleMassConc[i])==0)
            BBHG_BCcorr_ppb[i]=BBHG_LiquidSampleMassConc[i]/eB
            BBHG_BCcorrInt_ppb[i]=(BBHG_LiquidSampleMassConc[i]-iB)/eB
        endif
        if (numtype(eH)==0 && eH>0 && numtype(BHBL_LiquidSampleMassConc[i])==0)
            BHBL_BCcorr_ppb[i]=BHBL_LiquidSampleMassConc[i]/eH
            BHBL_BCcorrInt_ppb[i]=(BHBL_LiquidSampleMassConc[i]-iH)/eH
        endif
        if (numtype(StdTarget_rBC_ppb[i])==0 && StdTarget_rBC_ppb[i]>0)
            if (StringMatch(QCFlag[i],"STD_RECOVERY_*"))
                QCFlag[i]="OK"
            endif
            BBHG_Recovery_pct[i]=100*BBHG_BCcorr_ppb[i]/StdTarget_rBC_ppb[i]
            BHBL_Recovery_pct[i]=100*BHBL_BCcorr_ppb[i]/StdTarget_rBC_ppb[i]
            BBHG_Residual_ppb[i]=BBHG_BCcorr_ppb[i]-StdTarget_rBC_ppb[i]
            BHBL_Residual_ppb[i]=BHBL_BCcorr_ppb[i]-StdTarget_rBC_ppb[i]
            badBBHG=(numtype(BBHG_Recovery_pct[i])==0 && (BBHG_Recovery_pct[i]<80 || BBHG_Recovery_pct[i]>120))
            badBHBL=(numtype(BHBL_Recovery_pct[i])==0 && (BHBL_Recovery_pct[i]<80 || BHBL_Recovery_pct[i]>120))
            if (StringMatch(QCFlag[i],"OK"))
                if (badBBHG && badBHBL)
                    QCFlag[i]="STD_RECOVERY_BOTH"
                elseif (badBBHG)
                    QCFlag[i]="STD_RECOVERY_BBHG"
                elseif (badBHBL)
                    QCFlag[i]="STD_RECOVERY_BHBL"
                else
                    QCFlag[i]="OK"
                endif
            endif
        endif
    endfor

    WaveStats/Q CalNominal_ppb
    Variable maxNom=V_max
    Make/O/N=101 CalFitX=NaN,CalFitBBHG=NaN,CalFitBHBL=NaN
    CalFitX=p*maxNom/100
    CalFitBBHG=iB+sB*CalFitX
    CalFitBHBL=iH+sH*CalFitX
    Make/O/N=101 CalTargetLine=NaN
    CalTargetLine=p*(AQfrac*maxNom)/100

    // blank statistics in corrected BHBL units; LOD/LOQ only for >=10 independent blanks
    Variable nb=0,sumBl=0,sumBl2=0,bmean=NaN,bsd=NaN
    for (i=0;i<n;i+=1)
        if (BCIGE_IsBlank(SampleID[i]) && numtype(BHBL_BCcorr_ppb[i])==0)
            nb+=1
            sumBl+=BHBL_BCcorr_ppb[i]
            sumBl2+=BHBL_BCcorr_ppb[i]^2
        endif
    endfor
    if (nb>0)
        bmean=sumBl/nb
    endif
    if (nb>1)
        bsd=sqrt((sumBl2-nb*bmean^2)/(nb-1))
    endif
    NVAR g_nb=root:BCIGE:Nblanks
    g_nb=nb
    NVAR g_bm=root:BCIGE:BlankMean_BHBL
    g_bm=bmean
    NVAR g_bs=root:BCIGE:BlankSD_BHBL
    g_bs=bsd
    NVAR g_lod=root:BCIGE:LOD_BHBL
    NVAR g_loq=root:BCIGE:LOQ_BHBL
    if (nb>=10 && numtype(bsd)==0)
        g_lod=bmean+3*bsd
        g_loq=bmean+10*bsd
    else
        g_lod=NaN
        g_loq=NaN
    endif

    NVAR minR=root:BCIGE:MinCalR2
    SVAR stat=root:BCIGE:CalStatus
    stat="PASS"
    if (nlev<8)
        stat="WARNING: incomplete 8-level AquaDAG series"
    endif
    if ((numtype(rB)==0 && rB<minR) || (numtype(rH)==0 && rH<minR))
        stat="WARNING: calibration R2 below threshold"
    endif
    if (nb<10)
        stat=stat+"; formal LOD/LOQ not reported (Nblank<10)"
    endif
    Print "AquaDAG calibration | BBHG slope="+num2str(sB)+" intercept="+num2str(iB)+" R2="+num2str(rB)+" eff="+num2str(eB)
    Print "AquaDAG calibration | BHBL slope="+num2str(sH)+" intercept="+num2str(iH)+" R2="+num2str(rH)+" eff="+num2str(eH)
    Print "Calibration status: "+stat
    SetDataFolder $savedDF
    return 0
End

Function BCIGE_RecalBtn(ctrlName) : ButtonControl
    String ctrlName
    SVAR last=root:BCIGE:LastBatchFldr
    if (strlen(last)==0)
        Print "No timed batch folder selected."
        Return -1
    endif
    BCIGE_AutoCalibration(last)
    Return 0
End

Function BCIGE_OpenInputBtn(ctrlName) : ButtonControl
    String ctrlName
    SVAR last=root:BCIGE:LastBatchFldr
    if (strlen(last)>0)
        BCIGE_OpenInput(last)
    endif
    Return 0
End

Function BCIGE_OpenInput(BatchFldrFP)
    String BatchFldrFP
    String savedDF=GetDataFolder(1)
    SetDataFolder $BatchFldrFP
    Wave/T FileDate,FileNumList,SampleID,StartTime,StopTime
    Wave TrimStart_s,TrimEnd_s,LiqSampleFlow,LiqDrainFlow,PurgeAirFlow
    DoWindow/K BCIGE_TimedInput
    Edit/N=BCIGE_TimedInput/W=(25,80,1180,430) FileDate,FileNumList,SampleID,StartTime,StopTime,TrimStart_s,TrimEnd_s,LiqSampleFlow,LiqDrainFlow,PurgeAirFlow
    SetDataFolder $savedDF
    Return 0
End

Function BCIGE_OpenResultsBtn(ctrlName) : ButtonControl
    String ctrlName
    SVAR last=root:BCIGE:LastBatchFldr
    if (strlen(last)>0)
        BCIGE_OpenResults(last)
    endif
    Return 0
End

Function BCIGE_OpenResults(BatchFldrFP)
    String BatchFldrFP
    String savedDF=GetDataFolder(1)
    SetDataFolder $BatchFldrFP
    Wave/T FileDate,FileNumList,SampleID,StartTime,StopTime,QCFlag
    Wave TimeDateAvg,WindowSec,Ntriggers_Window
    Wave BBHG_LiquidSampleMassConc,BHBL_LiquidSampleMassConc,BBHG_BCcorr_ppb,BHBL_BCcorr_ppb
    Wave StdNominal_ppb,StdTarget_rBC_ppb,BBHG_Recovery_pct,BHBL_Recovery_pct
    DoWindow/K BCIGE_Results
    Edit/N=BCIGE_Results/W=(20,65,1460,620) FileDate,FileNumList,SampleID,StartTime,StopTime,WindowSec,Ntriggers_Window,BBHG_LiquidSampleMassConc,BHBL_LiquidSampleMassConc,BBHG_BCcorr_ppb,BHBL_BCcorr_ppb,StdNominal_ppb,StdTarget_rBC_ppb,BBHG_Recovery_pct,BHBL_Recovery_pct,QCFlag
    ModifyTable width(SampleID)=120,width(QCFlag)=145,width(BBHG_LiquidSampleMassConc)=115,width(BHBL_LiquidSampleMassConc)=115,width(BBHG_BCcorr_ppb)=100,width(BHBL_BCcorr_ppb)=100
    SetDataFolder $savedDF
    Return 0
End

Function BCIGE_CalTableBtn(ctrlName) : ButtonControl
    String ctrlName
    SVAR last=root:BCIGE:LastBatchFldr
    if (strlen(last)>0)
        BCIGE_OpenCalTable(last)
    endif
    Return 0
End

Function BCIGE_OpenCalTable(BatchFldrFP)
    String BatchFldrFP
    String savedDF=GetDataFolder(1)
    SetDataFolder $BatchFldrFP
    Wave CalNominal_ppb,CalTarget_rBC_ppb,Cal_BBHG_raw,Cal_BHBL_raw,Cal_BBHG_corr,Cal_BHBL_corr,Cal_BBHG_recovery,Cal_BHBL_recovery,Cal_BBHG_resid,Cal_BHBL_resid
    DoWindow/K BCIGE_CalTable
    Edit/N=BCIGE_CalTable/W=(45,90,1280,520) CalNominal_ppb,CalTarget_rBC_ppb,Cal_BBHG_raw,Cal_BHBL_raw,Cal_BBHG_corr,Cal_BHBL_corr,Cal_BBHG_recovery,Cal_BHBL_recovery,Cal_BBHG_resid,Cal_BHBL_resid
    SetDataFolder $savedDF
    Return 0
End

Function BCIGE_CalGraphBtn(ctrlName) : ButtonControl
    String ctrlName
    SVAR last=root:BCIGE:LastBatchFldr
    if (strlen(last)>0)
        BCIGE_CalibrationGraphs(last)
    endif
    Return 0
End

Function BCIGE_CalibrationGraphs(BatchFldrFP)
    String BatchFldrFP
    String savedDF=GetDataFolder(1)
    SetDataFolder $BatchFldrFP
    Wave CalNominal_ppb,CalTarget_rBC_ppb,Cal_BBHG_raw,Cal_BHBL_raw,Cal_BBHG_corr,Cal_BHBL_corr
    Wave Cal_BBHG_resid,Cal_BHBL_resid,CalFitX,CalFitBBHG,CalFitBHBL,CalTargetLine
    NVAR sB=BBHG_CalSlope
    NVAR iB=BBHG_CalIntercept
    NVAR rB=BBHG_CalR2
    NVAR eB=BBHG_Efficiency
    NVAR sH=BHBL_CalSlope
    NVAR iH=BHBL_CalIntercept
    NVAR rH=BHBL_CalR2
    NVAR eH=BHBL_Efficiency
    DoWindow/K BCIGE_Calibration
    Display/N=BCIGE_Calibration/W=(40,70,760,520) Cal_BBHG_raw vs CalNominal_ppb
    AppendToGraph Cal_BHBL_raw vs CalNominal_ppb
    AppendToGraph CalFitBBHG vs CalFitX
    AppendToGraph CalFitBHBL vs CalFitX
    ModifyGraph mode(Cal_BBHG_raw)=3,marker(Cal_BBHG_raw)=19,mode(Cal_BHBL_raw)=3,marker(Cal_BHBL_raw)=17
    ModifyGraph lsize(CalFitBBHG)=2,lsize(CalFitBHBL)=2
    Label left "Measured liquid rBC [ug/L]"
    Label bottom "Nominal AquaDAG [ppb total mass]"
    Legend/C/N=text0/J/A=LT "\\s(Cal_BBHG_raw) BBHG\r\\s(Cal_BHBL_raw) BHBL\r\\s(CalFitBBHG) BBHG fit\r\\s(CalFitBHBL) BHBL fit"
    TextBox/C/N=fitinfo/A=RB/X=1/Y=1 "BBHG: slope="+num2str(sB)+", R2="+num2str(rB)+", eff="+num2str(eB)+"\rBHBL: slope="+num2str(sH)+", R2="+num2str(rH)+", eff="+num2str(eH)

    DoWindow/K BCIGE_Residuals
    Display/N=BCIGE_Residuals/W=(780,70,1460,520) Cal_BBHG_resid vs CalTarget_rBC_ppb
    AppendToGraph Cal_BHBL_resid vs CalTarget_rBC_ppb
    ModifyGraph mode=3,marker(Cal_BBHG_resid)=19,marker(Cal_BHBL_resid)=17
    Label left "Residual corrected rBC [ppb]"
    Label bottom "Expected rBC in AquaDAG standard [ppb]"
    Legend/C/N=text0/J/A=LT "\\s(Cal_BBHG_resid) BBHG\r\\s(Cal_BHBL_resid) BHBL"
    SetDataFolder $savedDF
    Return 0
End

Function BCIGE_ResultGraphBtn(ctrlName) : ButtonControl
    String ctrlName
    SVAR last=root:BCIGE:LastBatchFldr
    if (strlen(last)>0)
        BCIGE_ResultGraph(last)
    endif
    Return 0
End

Function BCIGE_ResultGraph(BatchFldrFP)
    String BatchFldrFP
    String savedDF=GetDataFolder(1)
    SetDataFolder $BatchFldrFP
    Wave BBHG_BCcorr_ppb,BHBL_BCcorr_ppb
    DoWindow/K BCIGE_ResultGraphWin
    Display/N=BCIGE_ResultGraphWin/W=(90,90,950,570) BBHG_BCcorr_ppb
    AppendToGraph BHBL_BCcorr_ppb
    ModifyGraph mode=4,marker(BBHG_BCcorr_ppb)=19,marker(BHBL_BCcorr_ppb)=17
    Label left "Efficiency-corrected rBC [ppb]"
    Label bottom "Timed sample row"
    Legend/C/N=text0/J/A=LT "\\s(BBHG_BCcorr_ppb) BBHG\r\\s(BHBL_BCcorr_ppb) BHBL"
    SetDataFolder $savedDF
    Return 0
End

Function BCIGE_QCTableBtn(ctrlName) : ButtonControl
    String ctrlName
    SVAR last=root:BCIGE:LastBatchFldr
    if (strlen(last)>0)
        BCIGE_OpenQCTable(last)
    endif
    Return 0
End

Function BCIGE_OpenQCTable(BatchFldrFP)
    String BatchFldrFP
    String savedDF=GetDataFolder(1)
    SetDataFolder $BatchFldrFP
    Wave/T SampleID,QCFlag
    Wave StdNominal_ppb,StdTarget_rBC_ppb,BBHG_Recovery_pct,BHBL_Recovery_pct,BBHG_Residual_ppb,BHBL_Residual_ppb,BBHG_BCcorrInt_ppb,BHBL_BCcorrInt_ppb
    DoWindow/K BCIGE_QC
    Edit/N=BCIGE_QC/W=(60,100,1250,530) SampleID,StdNominal_ppb,StdTarget_rBC_ppb,BBHG_Recovery_pct,BHBL_Recovery_pct,BBHG_Residual_ppb,BHBL_Residual_ppb,BBHG_BCcorrInt_ppb,BHBL_BCcorrInt_ppb,QCFlag
    SetDataFolder $savedDF
    Return 0
End

