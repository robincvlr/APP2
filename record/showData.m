## Copyright (c) 2014, Simon Brodeur
## All rights reserved.
## 
## Redistribution and use in source and binary forms, with or without modification,
## are permitted provided that the following conditions are met:
## 
##  - Redistributions of source code must retain the above copyright notice, 
##    this list of conditions and the following disclaimer.
##  - Redistributions in binary form must reproduce the above copyright notice, 
##    this list of conditions and the following disclaimer in the documentation 
##    and/or other materials provided with the distribution.
##  - Neither the name of Simon Brodeur nor the names of its contributors 
##    may be used to endorse or promote products derived from this software 
##    without specific prior written permission.
## 
## THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
## ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
## WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
## IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
## INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT 
## NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
## OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
## WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
## ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
## POSSIBILITY OF SUCH DAMAGE.
##

## Author: Simon Brodeur <simon.brodeur@usherbrooke.ca>

## Close any existing figures
close all;

## Set seed of random number generator for reproducible results
rand('seed',0);

## usage: T = getAbsoluteTime(CURLAPTIME)
##
## Convert the current lap time vector into absolute time. This is because time
## is otherwise reset to zero once a lap is complete.
##
## Input:
## - CURLAPTIME, the lap-relative time vector.
##
## Output:
## - T, the absolute time vector.
##
function t = getAbsoluteTime(curLapTime)
  t = zeros(size(curLapTime));
  t(1) = curLapTime(1);
  for i=2:length(curLapTime)
    dt = curLapTime(i) - curLapTime(i-1);
    if dt < 0
      ## New lap
      dt = curLapTime(i);
    endif
    t(i) = t(i-1) + dt;
  endfor
endfunction

## Load state data from file
filepath = "./data/forza.mat";
disp(sprintf('Loading data from file %s', filepath));
data = load(filepath).data;
N = length(data);
disp(sprintf('Number of states found: %d', N));
t = getAbsoluteTime([data.curLapTime]);
## The following variables are available:
## data.accelCmd       data.damage         data.gear           data.racePos        data.steerCmd
## data.angle          data.distFromStart  data.gearCmd        data.rpm            data.track
## data.brakeCmd       data.distRaced      data.lastLapTime    data.speedX         data.trackPos
## data.curLapTime     data.fuel           data.opponents      data.speedY         data.wheelSpinVel

## Show car acceleration and brake commands
figure()
subplot(2,1,1)
plot(t,[data.accelCmd] * 100);
title('Car acceleration command');
xlabel('Time [sec]');
ylabel('Acceleration [%]');
axis('tight')
subplot(2,1,2)
plot(t,[data.brakeCmd] * 100);
title('Car brake command');
xlabel('Time [sec]');
ylabel('Brake [%]');
axis('tight')

## Show car steering and gear commands
figure()
subplot(2,1,1)
plot(t,[data.steerCmd] * 0.785398);
title('Car steering command');
xlabel('Time [sec]');
ylabel('Steering angle [rad]');
axis('tight')
subplot(2,1,2)
plot(t,[data.gearCmd]);
title('Tranmission gear command');
xlabel('Time [sec]');
ylabel('Gear');
axis('tight')

## Show car speed along longitudinal and transverse axes
figure()
subplot(2,1,1)
plot(t,[data.speedX]);
title('Car speed (longitudinal axis)');
xlabel('Time [sec]');
ylabel('Speed [km/h]');
axis('tight')
subplot(2,1,2)
plot(t,[data.speedY]);
title('Car speed (transverse axis)');
xlabel('Time [sec]');
ylabel('Speed [km/h]');
axis('tight')

## Show car speed along longitudinal axis, selected gear and engine rpm
figure()
subplot(3,1,1)
plot(t,[data.speedX]);
title('Car speed (longitudinal axis)');
xlabel('Time [sec]');
ylabel('Speed [km/h]');
axis('tight')
subplot(3,1,2)
plot(t,[data.gear]);
title('Tranmission gear');
xlabel('Time [sec]');
ylabel('Gear');
axis('tight')
subplot(3,1,3)
plot(t,[data.rpm]);
title('Engine rpm');
xlabel('Time [sec]');
ylabel('RPM');
axis('tight')

## Show wheel speed velocities
figure()
plot(t,[data.wheelSpinVel]);
title('Wheel speed velocity');
xlabel('Time [sec]');
ylabel('Angular speed [rad/s]');
axis('tight')
legend ({'front-right','front-left','rear-right','rear-left'});

# Show track position
figure()
plot(t,[data.trackPos]);
title('Track position');
xlabel('Time [sec]');
ylabel('Track position');
axis('tight')

## Fuel consumption and distance raced
## WARNING: fuel may have been disabled during the simulation!
figure()
subplot(2,1,1)
plot(t,[data.distRaced]);
title('Distance covered by the car');
xlabel('Time [sec]');
ylabel('Distance [m]');
axis('tight')
subplot(2,1,2)
plot(t,max([data.fuel]) - [data.fuel]);
title('Fuel consumed');
xlabel('Time [sec]');
ylabel('Fuel volume [l]');
xlim([min(t), max(t)])

## Car damage
## WARNING: car damage may have been disabled during the simulation!
figure()
plot(t,[data.damage]);
title('Car damage');
xlabel('Time [sec]');
ylabel('Damage points');
xlim([min(t), max(t)])

## Track distance
figure()
for i=1:4
  subplot(2,2,i);
  ## Sensor angles
  theta = [-90,-80,-70,-60,-50,-40,-30,-20,-10,0,10,20,30,40,50,60,70,80,90] * pi/180;
  ## Pick a random state
  stateIdx = randint(1,1, [1, N]);
  ## Convert distance vectors from polar to cartesian coordinates.
  track = [data.track](:,stateIdx)'; 
  x = sin(theta) .* track;
  y = cos(theta) .* track;
  ## Polar plot
  compass(x,y);
  hold on;
  plot(x,y,'ok','MarkerSize',5,'LineWidth',3)
  title(sprintf('Track distance (sensor array), state=%d',stateIdx));
  axis([-25,25,-10,100]);
endfor
