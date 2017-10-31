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

## Avoid the console blocking
more off;

## Merge all .mat files in the data folder to a single dataset.
## Loop for each file found in the data folder
data = [];
files = glob('./data/*.mat');
for i=1:numel(files)
  ## Load state data from file
	disp(sprintf('Loading data from file %s', files{i}));
	[~, name] = fileparts(files{i});
	fileData = load(files{i}).data;
	disp(sprintf('Number of states found: %d', length(fileData)));

  ## Append state data
  data = [data, fileData];
endfor

## Display statistics
disp('########################################');
disp(sprintf('Total number of states: %d', length(data)));
disp('########################################');

## Save data to disk
outputDir = "./dataset";
outputFile = [outputDir, "/all.mat"];
if (exist(outputDir) ~= 7)
    ## Create output folder if necessary
    fprintf('Creating output folder %s...\n',outputDir);
    mkdir(outputDir);
end
save("-mat-binary", outputFile, "data");
