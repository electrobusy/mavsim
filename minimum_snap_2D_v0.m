% MSc Student: Rohan Chotalal
% Supervisors: Guido De Croon and Christophe D' Waghter
% Faculty: Aerospace Engineering, TU Delft.

% Minimum Snap Algorithm (Mellinger and Kumar) - 2-D going from 1 Waypoint
% to another using a 6-th order polynomial

clc,
clear all,
close all

% -- keyframes = [x y]' (where x and y are column vectors)
keyframes = [
        0,0;
        4,6;
    ]';

% -- number of keyframes: 
[~,m] = size(keyframes);

% -- polynomial order: 
n = 6; % choose order 

% -- total time: 
t_m = 5; % [sec]

% -- vector of times:
t = [0, t_m]; % [t_0, t_1, ..., t_m]
% t_vec = t(2:end-1); % [t_1, ..., t_{m-1}]

% -- derivatives to minimize: 
k_x = 4; % snap

%% -----------------------------------------------------------------------

% Let's consider a polynomial: x(t) = t^n + t^{n-1} + ... + t^2 + t + 1 
x = ones(m-1,n+1);
% Same for y(t): 
y = ones(m-1,n+1);

% Think that in each term of the polynomial, the coeficient c_i is being
% multiplied, where i = {n, ... ,0}
% - for polynomial x
dx = polyder(x);
ddx = polyder(dx);
dddx = polyder(ddx);
ddddx = polyder(dddx);
% - for polynomial y: 
dy = polyder(y);
ddy = polyder(dy);
dddy = polyder(ddy);
ddddy = polyder(dddy);

% -- Construct A_eq matrix and b_eq vector
% - for x: 
A_x = [
    % waypoint constraints: sigma(t_i) = sigma_i
    polyval_terms(x,t(1)); % t_0
    polyval_terms(x,t(2)); % t_m
    % derivatives (in the first and last waypoints) d^{p}sigma/dt^{p} = 0 (or free)
    polyval_terms(dx,t(1)) 0;
    polyval_terms(ddx,t(1)) 0 0;
    % polyval_terms(dddx,t(1)) 0 0 0;
    % polyval_terms(ddddx,t(1)) 0 0 0 0; 
    polyval_terms(dx,t(2)) 0;
    polyval_terms(ddx,t(2)) 0 0;
    % polyval_terms(dddx,t(2)) 0 0 0;
    % polyval_terms(ddddx,t(2)) 0 0 0 0; 
    ];

b_x = [
    keyframes(1,1);
    keyframes(1,2);
    0; 
    0; 
    % inf; 
    % inf;
    0; 
    0; 
    % inf; 
    % inf;
    ];

% - for y: 
A_y = [
    % waypoint constraints: sigma(t_i) = sigma_i
    polyval_terms(y,t(1)); % t_0
    polyval_terms(y,t(2)); % t_m
    % derivatives (in the first and last waypoints) d^{p}sigma/dt^{p} = 0 (or free)
    polyval_terms(dy,t(1)) 0;
    polyval_terms(ddy,t(1)) 0 0;
    % polyval_terms(dddy,t(1)) 0 0 0;
    % polyval_terms(ddddy,t(1)) 0 0 0 0; 
    polyval_terms(dy,t(2)) 0;
    polyval_terms(ddy,t(2)) 0 0;
    % polyval_terms(dddy,t(2)) 0 0 0;
    % polyval_terms(ddddy,t(2)) 0 0 0 0; 
    ];

b_y = [
    keyframes(2,1);
    keyframes(2,2);
    0; 
    0; 
    % inf; 
    % inf;
    0; 
    0; 
    % inf; 
    % inf;
    ];

% - Obtain A_eq using the block matrix form and concatenate b_x and b_y to
% get b_eq:
A_eq = blkdiag(A_x,A_y);
b_eq = [b_x; b_y];

% -- Define A matrix and b vector 
% [NO INEQUALITY CONTRAINTS IN THIS CASE]

% -- Define Hessian matrix
H_x = zeros(n+1,n+1);
H_y = zeros(n+1,n+1);

% - for x: 
for i = 1:length(ddddx)
    aux = zeros(1,length(ddddx));
    aux(i) = ddddx(i);
    conv_pol = conv(ddddx,aux);
    aux_int_pol = polyint(conv_pol);
    res = polyval_terms(aux_int_pol,t_m);
    H_x(i,1:length(ddddx)) = res(res > 0);
end

% - for y:
for i = 1:length(ddddy)
    aux = zeros(1,length(ddddy));
    aux(i) = ddddy(i);
    conv_pol = conv(ddddy,aux);
    aux_int_pol = polyint(conv_pol);
    res = polyval_terms(aux_int_pol,t_m);
    H_y(i,1:length(ddddy)) = res(res > 0);
end

H = blkdiag(H_x,H_y);

% -- Solves quadratic programming problem: 
f = zeros(2*(n+1),1);
sol = quadprog(H,f,[],[],A_eq,b_eq);

% -- Plots:
dt = 0.01;
t = 0:dt:t_m;

pol_x = x.*sol(1:n+1)';
d_pol_x = dx.*sol(1:n+1-1)';
dd_pol_x = ddx.*sol(1:n+1-2)';
ddd_pol_x = dddx.*sol(1:n+1-3)';
dddd_pol_x = ddddx.*sol(1:n+1-4)';

pol_y = y.*sol(n+2:2*n+2)';
d_pol_y = dy.*sol(n+2:2*n+2-1)';
dd_pol_y = ddy.*sol(n+2:2*n+2-2)';
ddd_pol_y = dddy.*sol(n+2:2*n+2-3)';
dddd_pol_y = ddddy.*sol(n+2:2*n+2-4)';

figure(1);
subplot(3,2,[1 2])
plot(t,polyval(pol_x,t));
xlabel('t [sec]');
ylabel('x [m]');
grid on;

subplot(3,2,3)
plot(t,polyval(d_pol_x,t));
xlabel('t [sec]');
ylabel('v_x [m/s]');
grid on;

subplot(3,2,4)
plot(t,polyval(dd_pol_x,t));
xlabel('t [sec]');
ylabel('a_x [m/s^2]');
grid on;

subplot(3,2,5)
plot(t,polyval(ddd_pol_x,t));
xlabel('t [sec]');
ylabel('j_x [m/s^3]');
grid on;

subplot(3,2,6)
plot(t,polyval(dddd_pol_x,t));
xlabel('t [sec]');
ylabel('s_x [m/s^4]');
grid on;

figure(2);
subplot(3,2,[1 2])
plot(t,polyval(pol_y,t));
xlabel('t [sec]');
ylabel('y [m]');
grid on;

subplot(3,2,3)
plot(t,polyval(d_pol_y,t));
xlabel('t [sec]');
ylabel('v_y [m/s]');
grid on;

subplot(3,2,4)
plot(t,polyval(dd_pol_y,t));
xlabel('t [sec]');
ylabel('a_y [m/s^2]');
grid on;

subplot(3,2,5)
plot(t,polyval(ddd_pol_y,t));
xlabel('t [sec]');
ylabel('j_y [m/s^3]');
grid on;

subplot(3,2,6)
plot(t,polyval(dddd_pol_y,t));
xlabel('t [sec]');
ylabel('s_y [m/s^4]');
grid on;

figure(3);
V = sqrt(polyval(d_pol_x,t).^2 + polyval(d_pol_y,t).^2);
x_data = polyval(d_pol_x,t);
y_data = polyval(d_pol_y,t);
surf([x_data(:) x_data(:)], [y_data(:) y_data(:)], [V(:) V(:)], ...  % Reshape and replicate data
     'FaceColor', 'none', ...    % Don't bother filling faces with color
     'EdgeColor', 'interp', ...  % Use interpolated color for edges
     'LineWidth', 2);            % Make a thicker line
view(2);   % Default 2-D view
c = colorbar;  % Add a colorbar
c.Label.String = 'V [m/s]';
xlabel('x [m]');
ylabel('y [m]');
grid on;