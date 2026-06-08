clc; close all;

Da = xlsread('Curvas_Medidas_Motor_2026.xls');

% datos extraidos de la tabla del excel

t = Da(:,1);      % tiempo
y = Da(:,2);      % velocidad wr
u_va = Da(:,4);   % Vin REAL
u_tl = Da(:,5);   % TL REAL

%figure(1)
%plot(t,y)
%grid on
%title('Velocidad \omega_r')
%xlabel('Tiempo [s]')
%ylabel('\omega_r')

% Modelizacion de Va/Wr

StepAmplitude = 10;
wr = 66.67;

i = 400; %400
n = 135; %100

y_1 = Da(i,2);
x_1 = Da(i,1);

y_2 = Da(i+n,2);
x_2 = Da(i+n,1);

y_3 = Da(i+2*n,2);
x_3 = Da(i+2*n,1);

k = wr / StepAmplitude;

k1 = (1 / StepAmplitude) * y_1 / k - 1;
k2 = (1 / StepAmplitude) * y_2 / k - 1;
k3 = (1 / StepAmplitude) * y_3 / k - 1;

be = 4*k1^3*k3 - 3*k1^2*k2^2 - 4*k2^3 + k3^2 + 6*k1*k2*k3;

alfa1 = (k1*k2 + k3 - sqrt(be)) / (2*(k1^2 + k2));
alfa2 = (k1*k2 + k3 + sqrt(be)) / (2*(k1^2 + k2));

beta = (k1 + alfa2) / (alfa1 - alfa2);

T1 = -1.35 / log(alfa1);
T2 = -1.35 / log(alfa2);
T3 = beta*(T1 - T2) + T1;

s = tf('s');

G = 1 / ((T1*s +1)*(T2*s +1));
G_real = k * G 
FdtIa= minreal((k)*(T3*s+1)/((T1*s+1)*(T2*s+1)))
% Modelizacion Tl/Wr

Tl = 20;
w1 = 66.7;
w2 = 53.32;

i = 1950; %1880 a 2200
n = 100; %150
%1850 a 2120
yy_1 = y(i);
yy_2 = y(i+n);
yy_3 = y(i+2*n);

kt = -(w2 - w1) / Tl;

yid_1 = -(yy_1 - w1);
yid_2 = -(yy_2 - w1);
yid_3 = -(yy_3 - w1);

kt1 = (1 / Tl) * yid_1 / kt - 1;
kt2 = (1 / Tl) * yid_2 / kt - 1;
kt3 = (1 / Tl) * yid_3 / kt - 1;

bet = 4*kt1^3*kt3 - 3*kt1^2*kt2^2 - 4*kt2^3 + kt3^2 + 6*kt1*kt2*kt3;

if bet >= 0
    alfa1 = (kt1*kt2 + kt3 - sqrt(bet)) / (2*(kt1^2 + kt2));
    alfa2 = (kt1*kt2 + kt3 + sqrt(bet)) / (2*(kt1^2 + kt2));
else
    alfa1 = (kt1*kt2 + kt3 - sqrt(complex(bet))) / (2*(kt1^2 + kt2));
    alfa2 = (kt1*kt2 + kt3 + sqrt(complex(bet))) / (2*(kt1^2 + kt2));
end
dt = t(i+n) - t(i);
T1_tl = -dt / log(alfa1);
T2_tl = -dt / log(alfa2);

beta_tl = (2*kt1^3 + 3*kt1*kt2 + kt3 - sqrt(abs(bet))) / sqrt(abs(bet));
T3_tl = beta_tl*(T1_tl - T2_tl) + T1_tl;

T1_tl = real(T1_tl);
T2_tl = real(T2_tl);
T3_tl = real(T3_tl);

if abs(T1_tl - T2_tl) < 1e-6
    T2_tl = T1_tl * 1.01;
end

Gt = kt * (T3_tl*s + 1) / ((T1_tl*s +1)*(T2_tl*s +1))
%Gt = kt * 1 / ((T1_tl*s +1)*(T2_tl*s +1))
%Modelizacion de las Señales Obtenidas

y_va = lsim(G_real, u_va, t);
y_tl = lsim(Gt, u_tl, t);

%Modelo Final Obtenido

y_total = y_va - y_tl;

%Grafico Final

figure
plot(t, y, 'b', 'LineWidth', 1.5)
hold on
plot(t, y_total, 'r--', 'LineWidth', 1.5)
grid on
legend('Real','Modelo')
xlabel('Tiempo [s]')
ylabel('\omega_r')
title('Modelo Final con señales reales')