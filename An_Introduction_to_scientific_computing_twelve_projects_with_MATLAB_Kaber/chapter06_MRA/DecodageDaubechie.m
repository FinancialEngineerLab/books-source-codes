function DJ=DecodageDaubechie(J,CJ)

C0=(1+sqrt(3))/(4*sqrt(2));
C1=(3+sqrt(3))/(4*sqrt(2));
C2=(3-sqrt(3))/(4*sqrt(2));
C3=(1-sqrt(3))/(4*sqrt(2));

%synthesis
if size(CJ,1)<size(CJ,2)
    for j=0:J-1
        DJ=CJ;
        CJ(1:2:2^(j+1)-1)=C3*[DJ(2^j),DJ(1:2^j-1)]...
            -C0*[DJ(2^(j+1)),DJ(2^j+1:2^(j+1)-1)]...
            +C1*DJ(1:2^j)...
            -C2*DJ(2^j+1:2^(j+1));
        CJ(2:2:2^(j+1))= C2*DJ(1:2^j)...
            +C1*DJ(2^j+1:2^(j+1))...
            +C0*[DJ(2:2^j),DJ(1)]...
            +C3*[DJ(2^j+2:2^(j+1)),DJ(2^j+1)];
    end
else
    for j=0:J-1
        DJ=CJ;
        CJ(1:2:2^(j+1)-1)=C3*[DJ(2^j);DJ(1:2^j-1)]...
            -C0*[DJ(2^(j+1));DJ(2^j+1:2^(j+1)-1)]...
            +C1*DJ(1:2^j)...
            -C2*DJ(2^j+1:2^(j+1));
        CJ(2:2:2^(j+1))= C2*DJ(1:2^j)...
            +C1*DJ(2^j+1:2^(j+1))...
            +C0*[DJ(2:2^j);DJ(1)]...
            +C3*[DJ(2^j+2:2^(j+1));DJ(2^j+1)];
    end
end
DJ=CJ;