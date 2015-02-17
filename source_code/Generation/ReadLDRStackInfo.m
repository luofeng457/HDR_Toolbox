function exposure = ReadLDRStackInfo(dir_name, format)
%
%       exposure = ReadLDRInfo(dir_name, format)
%
%       This function reads information from an LDR image file.
%
%        Input:
%           -dir_name: the folder name where the stack is stored.
%           -format: an LDR format for reading LDR images.
%
%        Output:
%           -exposure: a stack of exposure values from images in dir_name
%
%     Copyright (C) 2011  Francesco Banterle
% 
%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with this program.  If not, see <http://www.gnu.org/licenses/>.
%

list = dir([dir_name, '/*.', format]);
n = length(list);
exposure = ones(n, 1);

for i=1:n
    %Read Exif file information   
    img_info = [];
    
    try
        if(exist('imfinfo') == 2)
            img_info = imfinfo([dir_name, '/', list(i).name]); 
        end
    catch err
        disp(err);
        
        try
            if(exist('exifread') == 2)
                img_info = exifread([dir_name, '/', list(i).name]);
                
                if(isfield(img_info, 'FNumber'))
                    img_info.DigitalCamera.FNumber = FNumber; 
                end
                
                if(isfield(img_info, 'ISOSpeedRatings'))
                    img_info.DigitalCamera.ISOSpeedRatings = ISOSpeedRatings; 
                end
                
                if(isfield(img_info, 'ExposureTime'))
                    img_info.DigitalCamera.ExposureTime = ExposureTime; 
                end                
                
            end
            
        catch err
            disp(err);
        end
    end
    
    if(~isempty(img_info)) 
        if(isfield(img_info, 'DigitalCamera'))
            exposure_time = img_info.DigitalCamera.ExposureTime;
            aperture = img_info.DigitalCamera.FNumber;
            iso = img_info.DigitalCamera.ISOSpeedRatings;

            [~, value] = EstimateAverageLuminance(exposure_time, aperture, iso);
            exposure(i) = value;
        else
            disp('WARNING: The LDR image does not have camera information!');
        end
    end
    
end

end