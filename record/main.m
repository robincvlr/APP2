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

## Avoid Octave thinking this is a function file 
1;

## Load the TORCS simulator functions for drive/control applications
source ../torcs_drive.m

###############################################
# Define helper functions here
###############################################

## usage: CONFIG = generateConfigFromTemplate(TEMPLATE, TRACKNAME, NBLAPS)
##
## Generate a XML configuration file for the simulator based on a template, where
## we can define the track name and maximum number of laps using variables ${TRACK_NAME}.
## and ${NB_LAPS}, respectively.
##
## Input:
## - TEMPLATE, the path of the template XML file.
## - TRACKNAME, the track name. Available road tracks:
##              'aalborg','alpine-1','alpine-2','brondehach','corkscrew'
##              'e-track-1','e-track-2','e-track-3','e-track-4','e-track-6'
##              'eroad','forza','g-track-1','g-track-2','g-track-3','ole-road-1'
##              'ruudskogen','spring','street-1','wheel-1','wheel-2'
## - NBLAPS, the maximum number of laps. When reached, the simulation automatically ends.
##
## Output:
## - CONFIG, the path of the generated XML configuration file. This is set to $PWD/config/race-config.xml .
##
function config = generateConfigFromTemplate(template, trackName='g-track-3', nbLaps=3)
  configStr = fileread(template);
  
  ## Track name variable
  if strfind(configStr, '${TRACK_NAME}')
    configStr = strrep(configStr, '${TRACK_NAME}', trackName);
  else
    error(sprintf('No TRACK_NAME variable found in template file: %s', template));
  endif
  
  ## Maximum number of laps variable
  if strfind(configStr, '${NB_LAPS}')
    configStr = strrep(configStr, '${NB_LAPS}', num2str(nbLaps));
  else
    error(sprintf('No NB_LAPS variable found in template file: %s', template));
  endif
  
  ## Write new config file to disk
  config = [pwd(), '/config/race-config.xml'];
  fid = fopen (config, "w");
  fputs (fid, configStr);
  fclose (fid);
  
endfunction

###############################################
# Define code logic here
###############################################

## IMPORTANT: uncomment the wanted simulation mode below:
## 'human' , player-controlled with graphical display
## 'bot-gui', bot with graphical display
## 'bot-nogui', bot without graphical display (fastest)
##
## Available tracks:
## 'aalborg','alpine-1','alpine-2','brondehach','corkscrew'
## 'e-track-1','e-track-2','e-track-3','e-track-4','e-track-6'
## 'eroad','forza','g-track-1','g-track-2','g-track-3','ole-road-1'
## 'ruudskogen','spring','street-1','wheel-1','wheel-2'

# Uncomment below to drive manually the car on a specific track
mode = 'human';
trackNames = {'forza'};
nbLaps = 1;

# Uncomment below to drive the car by a bot on a specific track
%mode = 'bot-gui'
%trackNames = {'aalborg'};
%nbLaps = 1;

# Uncomment below to drive the car by a bot on a all tracks (gui disabled)
%mode = 'bot-nogui'
%trackNames = {'aalborg','alpine-1','alpine-2','brondehach','corkscrew', ...
%          'e-track-1','e-track-2','e-track-3','e-track-4','e-track-6', ...
%          'eroad','forza','g-track-1','g-track-2','g-track-3','ole-road-1',...
%          'ruudskogen','spring','street-1','wheel-1','wheel-2'};
%nbLaps = 1;

## Loop for each track in the training dataset
for i=1:length(trackNames)
  trackName = trackNames{i};
  disp('##############################################')
  disp(sprintf('Simulating on track %s', trackName));
  disp(sprintf('Maximum number of laps: %d', nbLaps));
  disp('##############################################')
  
  try

    ## Reinitialize the TORCS simulator (i.e. reset socket, clear internal state buffer, etc.)
    reinitSimulator()
  
    ## NOTE: the unwind_protect block is necessary to shutdown the simulator
    ##       if any error occurs in the code. DO NOT REMOVE IT!
    unwind_protect

      if strcmp(mode, 'bot-nogui')
        ## Connect to simulation server as a bot with no graphical display.
        ## NOTE: This function is defined in the file torcs_drive.m
        template = [pwd(), '/config/template/race-config-bot-nogui.xml'];
        config = generateConfigFromTemplate(template,trackName,nbLaps);
        startSimulator('nogui', config);
      elseif strcmp(mode, 'bot-gui')
        ## Connect to simulation server as a bot with graphical display.
        ## NOTE: This function is defined in the file torcs_drive.m
        template = [pwd(), '/config/template/race-config-bot-gui.xml'];
        config = generateConfigFromTemplate(template,trackName,nbLaps);
        startSimulator('gui', config);
      elseif strcmp(mode, 'human')
        ## Connect to simulation server as a manual player with graphical display.
        ## NOTE: This function is defined in the file torcs_drive.m
        template = [pwd(), '/config/template/race-config-player-gui.xml'];
        config = generateConfigFromTemplate(template,trackName,nbLaps);
        startSimulator('gui', config);
      else
        error(sprintf("Unsupported simulation mode: %s", mode));
      endif
      
      ## Loop indefinitely, or until:
      ## - The maximum number of laps is reached in the simulation.
      ## - Simulator is shutdown using the menu (press ESC during the simulation).
      ## - Octave is terminated by CTRL-C on the Command Window.
      counter = 1;
      while 1
        ## Grab the car state from the simulator.
        ## NOTE: This function is defined in the file torcs_drive.m
        [state, status] = waitForState(blocking=0);
        if strcmp(status,"running") == 0
          ## Simulator is shutting down or no longer running, so exit.
          break;
        endif

        ## Record the current state and action in the internal saving buffer.
        ## NOTE: This function is defined in the file torcs_drive.m
        doRecord(state);
        
        ## Perform a saving operation every 100 recorded states.
        if mod(counter,100) == 0
          disp(sprintf("Saved %d states: distance raced = %1.1f km", counter, state.distRaced/1000.0));
          ## Save all recorded data accumulated so far.
          ## NOTE: This function is defined in the file torcs_drive.m
          saveRecordedData(sprintf('data/%s.mat',trackName));
        endif
        counter = counter + 1;
      endwhile
      
      ## Save all recorded data accumulated during the simulation to disk.
      ## NOTE: This function is defined in the file torcs_drive.m
      saveRecordedData(sprintf('data/%s.mat',trackName));

    unwind_protect_cleanup
      ## NOTE: this block of code is called on exit
      ## Close the simulator
      stopSimulator();
      disp('Done.');
    end_unwind_protect
  catch
    disp(lasterror.message);
    sleep(4);
  end_try_catch
  
endfor
disp('All done.');
