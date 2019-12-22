%% Bryson-Denham problem
import yop.*

t  = yop.variable('t');
x  = yop.variable('x', 2);
u  = yop.variable('u');
ocp = yop.optimization_problem(...
    't', t, 't0', 0, 'tf', 1, 'state', x, 'control',u);
ocp.minimize( 1/2*integral( u^2 ) );
ocp.subject_to( ...
    der(x)  == [x(2); u], ...
    x(t==0) == [0; 1],    ... 
    x(t==1) == [0;-1],    ...
    x(1)    <= 1/9        );
sol = ocp.solve();

figure(1)
subplot(211);
sol.plot(t, x(1));
subplot(212);
sol.plot(t, x(2));

figure(2)
sol.plot(t, u);

%% Bryson-denham alternativ implementation:
import yop.*

t  = variable('t');
x  = variable('x', 2);
u  = variable('u');

ocp = optimization_problem( ...
    't', t, 't0', 0,'tf', 1, 'state', x, 'control', u);

s = x(1); v = x(2); a = u;

ocp.minimize( 1/2*integral( a^2 ) );

ocp.subject_to( ...
    der(s) == v,              ...
    der(v) == a,              ...
    s(t==0) ==  s(t==1) == 0, ...
    v(t==0) == -v(t==1) == 1, ...
    s <= 1/9                  ...
    );

sol = ocp.solve();

figure(1)
subplot(211);
sol.plot(t, x(1));
subplot(212);
sol.plot(t, x(2));

figure(2)
sol.plot(t, u);

%% Goddard rocket
import yop.*
t0 = parameter('t0'); % end time
tf = parameter('tf'); % end time
t = variable('t'); % independent
x = variable('x', 3); % state
u = variable('u'); % control

rocket = rocket_model(x, u);

% create an optimization problem
ocp = optimization_problem( ...
    't', t, 't0', t0, 'tf', tf, 'state', x, 'control',u);

ocp.maximize( rocket.height(tf) );  

ocp.subject_to( ...
    0 == t0 <= tf, ...
    der(x) == rocket.dxdt, ...
    x(t0) == [0; 0; 215], ...   
    rocket.velocity >= 0, ...
    rocket.height >= 0, ...
    rocket.mass >= 67.9833, ...
    0  <= rocket.fuel_mass_flow <= 9.5 ...
   );   

sol = ocp.solve('control_intervals', 60);

%% Genset transient optimization
import yop.*

uf_max = constant('uf_max');
t0 = parameter('t0');
tf = parameter('tf');
t  = variable('t');

% Genset
x_ice = variable('x_ice', 'rows', 5);
u_ice = variable('u_ice', 'rows', 3);

genset = genset_model(x_ice, u_ice);

% Fuel controller (Basic PI without(!) integrator windup protection)
x_pid = variable('x_pid');
w_pid = variable('w_pid', 'rows', 3); % Inputs
p_pid = parameter('p_pid', 'rows', 2); % Kp, Ki

pid = fuel_controller(x_pid, w_pid, p_pid);

% Use ramp as reference for the generator output.
% ramp_parameters passed as second input:
%    [ramp_t0; ramp_tf; ramp_value_t0; ramp_value_tf]
ramp = power_reference(t, [1; 4; 0; 120e3]);

sim = simulator( ...
    't', t, ...
    'states', [x_ice; x_pid], ...
    'algebraics', [u; w_pid], ...
    'parameters', p_pid ...
    );

sim.problem(...
    der(x_ice) == genset.dxdt, ...
    der(x_pid) == pid.dxdt, ...
    0 == pid.engine_speed.acutal - genset.engine.speed, ...
    0 == pid.engine_speed.desired - rpm2rad(1500), ...
    0 == pid.fuel_limiter - genset.cylinder.fuel_limiter, ...
    0 == pid.control_signal - genset.cylinder.fuel_injection, ...   
    0 == genset.generator.power - ramp.value, ...
    0 == genset.wastegate ... % closed wg
    );

sim_res = sim.solve( ...
    'grid', linspace(0, 7, 1000), ...
    genset.engine.speed(t==0) == rpm2rad(800), ...
    genset.intake.pressure(t==0) ==  1.0143e+05, ...
    genset.exhaust.pressure(t==0) == 1.0975e+05, ...
    genset.turbocharger.speed(t==0) == 2.0502e+03, ...
    genset.generator.engery(t==0) == 0, ...
    pid.integral_state(t==0) == 0, ...
    pid.Kp == 2, ...
    pid.Ki == 1 ...
    );

% [plot simulation results]

% optimal control problem
ocp = optimization_problem( ...
    't', t, 't0', t0, 'tf', tf, 'state', x_ice, 'control',u_ice);

ocp.minimize( integral( genset.cylinder.fuel_massflow ) )

ocp.subject_to(...
    der(x_ice) == genset.dxdt, ...
    1.1 <= t <= 1.4, ...
    ... initial conditions
    genset.engine.speed(t0) == rpm2rad(800), ...
    genset.intake.pressure(t0) == 1.0143e+05, ...
    genset.exhaust.pressure(t0) == 1.0975e+05, ...
    genset.turbocharger.speed(t0) == 2.0502e+03, ...
    genset.generator.energy(t0) == 0, ...
    genset.wastegate(t0) == 0, ...
    ... terminal conditions
    genset.generator.power(tf) == 100e3, ...
    genset.generator.energy(tf) == 100e3, ...
    genset.dxdt(1:4).at(t0) == 0, ... '.t0' invokes a method call to 't0(obj)'
    ... Box constraints
    rpm2rad(800) <= genset.engine.speed       <= rpm2rad(2500), ...
    8.0889e+04   <= genset.intake.pressure    <= 350000, ...
    9.1000e+04   <= genset.exhaust.pressure   <= 400000, ...
       500       <= genset.turbocharger.speed <= 15000, ...
        0        <= genset.generator.energy   <= 300e3, ...
        0        <= genset.cylinder.fuel_injection <= uf_max, ...
        0        <= genset.wastegate.control  <= 1, ...
        0        <= genset.generator.power    <= 100e3, ...
    ... Path constraints
    genset.turbine.bsr_min <= genset.turbine.bsr <= genset.turbine.bsr_max, ...
    genset.engine.power <= genset.engine.power_limit(1), ...
    genset.engine.power <= genset.engine.power_limit(2), ...
    genset.cylinder.fuel_to_air_ratio >= genset.cylinder.lambda_min, ...
    genset.compressor.pressure_ratio <= genset.compressor.surge_line ... 
    );

% Scale problem
ocp.scale('objective', 'weight', 1e3);
ocp.scale(x, 'weight', [rpm2rad(1e-3); 1e-5; 1e-5; 1e-3; 1e-5]);
ocp.scale(u, 'weight', [1e-2; 1e-5; 1e-5]);

uf_max.value = 150;

sol = ocp.solve( ...
    'solver', 'ipopt', ...
    'solver_options', struct('acceptable_tol', 1e-7), ...
    'initial_guess', sim_res, ...
    'control_intervals', 75, ...
    'collocation_points', 'radau', ...
    'state_polynomial_degree', 3 ...
    );

uf_max.value = 200; 
sol2 = ocp.solve(sol.opts);

%%


%% Goddard model
function [dx, rocket, drag, gravity] = goddard_model(t, x, u)
% States and controls
v = x(1);
h = x(2);
m = x(3);
T = u;

% Parameters
c = 0.5;
g0 = 1;
h0 = 1;
D0 = 0.5*620;
b = 500;

% Drag
g = g0*(h0/h)^2;
D = D0*exp(-b*h);
F_D = D*v^2;

% Dynamics
dv = (T-sign(v)*F_D)/m-g;
dh = v;
dm = -T/c;
dx = [dv;dh;dm];

% Signals y
rocket.speed = v;
rocket.height = h;
rocket.fuelMass = m;
rocket.fuelMassFlow = dm;
rocket.thrust = T;
drag.coefficient = D;
drag.force = F_D;
gravity = g;
end