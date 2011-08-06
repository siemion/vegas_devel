%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   Center for Astronomy Signal Processing and Electronics Research           %
%   http://casper.berkeley.edu                                                %      
%   Copyright (C) 2011 Suraj Gowda                                            %
%                                                                             %
%   This program is free software; you can redistribute it and/or modify      %
%   it under the terms of the GNU General Public License as published by      %
%   the Free Software Foundation; either version 2 of the License, or         %
%   (at your option) any later version.                                       %
%                                                                             %
%   This program is distributed in the hope that it will be useful,           %
%   but WITHOUT ANY WARRANTY; without even the implied warranty of            %
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             %
%   GNU General Public License for more details.                              %
%                                                                             %
%   You should have received a copy of the GNU General Public License along   %
%   with this program; if not, write to the Free Software Foundation, Inc.,   %
%   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.               %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function coeff_gen_init_xblock(Coeffs, coeff_bit_width, StepPeriod, bram_latency, coeffs_bram)

%% initialization scripts

if( ~isempty(find(real(Coeffs) > 1, 1)) || ~isempty(find(imag(Coeffs) > 1, 1)) ),
    clog(['coeff_gen_init: [',num2str(Coeffs,4),'] not all in range [-1->1]'],'error');
    error('coeff_gen_init: Coefficients specified are out of range');
    return;
end


%% inports
rst = xInport('rst');

%% outports
w = xOutport('w');

%% diagram
                 

                  
                  

                    

if length(Coeffs) == 1,
        
    %terminator
    Terminator = xBlock(struct('source','Terminator', 'name', 'Terminator'), ...
                               [], ...
                               {rst}, ...
                               {});
    %constant blocks
    real_coeff = round(real(Coeffs(1)) * 2^(coeff_bit_width-2)) / 2^(coeff_bit_width-2);
    imag_coeff = round(imag(Coeffs(1)) * 2^(coeff_bit_width-2)) / 2^(coeff_bit_width-2);
    Coeffs
    real_coeff
    imag_coeff
    
    % block: untitled/coeff_gen/Constant
    Constant_out1 = xSignal;
    Constant = xBlock(struct('source', 'Constant', 'name', 'Constant'), ...
                             struct('n_bits', coeff_bit_width, ...
                                    'bin_pt', coeff_bit_width-2, ...
                                    'const', real_coeff, ...
                                    'explicit_period', 'on', ...
                                    'period', 1), ...
                             {}, ...
                             {Constant_out1});

    % block: untitled/coeff_gen/Constant1
    Constant1_out1 = xSignal;
    Constant1 = xBlock(struct('source', 'Constant', 'name', 'Constant1'), ...
                              struct('const', imag_coeff, ...
                                     'n_bits', coeff_bit_width, ...
                                     'bin_pt', coeff_bit_width-2, ...
                                     'explicit_period', 'on', ...
                                     'period', 1), ...
                              {}, ...
                              {Constant1_out1});
 
                          % block: twiddles_collections/coeff_gen/ri_to_c
    ri_to_c = xBlock(struct('source', 'casper_library_misc/ri_to_c', 'name', 'ri_to_c'), ...
                          [], ...
                           {Constant_out1, Constant1_out1}, ...
                           {w});
else
    vlen = length(Coeffs);
    if( strcmp(coeffs_bram, 'on')),
        mem = 'Block RAM';
    else
        mem = 'Distributed memory';
    end
    real_coeffs = round( real(Coeffs) * 2^(coeff_bit_width-2) ) / 2^(coeff_bit_width-2)
    imag_coeffs = round( imag(Coeffs) * 2^(coeff_bit_width-2)  ) / 2^(coeff_bit_width-2)
    
    % block: twiddles_collections/coeff_gen/Counter
    Counter_out1 = xSignal;
    Counter = xBlock(struct('source', 'Counter', 'name', 'Counter'), ...
                            struct('n_bits', log2(vlen)+StepPeriod, ...
                                   'cnt_type', 'Free Running', ...
                                   'start_count', 0, ...
                                   'cnt_by_val', 1, ...
                                   'arith_type', 'Unsigned', ...
                                   'bin_pt', 0, ...
                                   'rst', 'on'), ...
                            {rst}, ...
                            {Counter_out1});

    % block: twiddles_collections/coeff_gen/ROM
    Slice_out1 = xSignal;
    ROM_out1 = xSignal;
    ROM = xBlock(struct('source', 'ROM', 'name', 'ROM'), ...
                        struct('depth', length(Coeffs), ...
                               'initVector', real_coeffs, ...
                               'distributed_mem', mem, ...
                               'latency', bram_latency, ...
                               'n_bits', coeff_bit_width, ...
                               'bin_pt', coeff_bit_width-2), ...
                        {Slice_out1}, ...
                        {ROM_out1});

    % block: twiddles_collections/coeff_gen/ROM1
    ROM1_out1 = xSignal;
    ROM1 = xBlock(struct('source', 'ROM', 'name', 'ROM1'), ...
                         struct('depth', length(Coeffs), ...
                                'initVector', imag_coeffs, ...
                                'distributed_mem', mem, ...
                                'latency', bram_latency, ...
                                'n_bits', coeff_bit_width, ...
                                'bin_pt', coeff_bit_width-2), ...
                         {Slice_out1}, ...
                         {ROM1_out1});

    % block: twiddles_collections/coeff_gen/Slice
    Slice = xBlock(struct('source', 'Slice', 'name', 'Slice'), ...
                          struct('nbits', log2(vlen), ...
                                 'mode', 'Upper Bit Location + Width', ...
                                 'bit1', 0, ...
                                 'base1', 'MSB of Input'), ...
                          {Counter_out1}, ...
                          {Slice_out1});


    % block: twiddles_collections/coeff_gen/ri_to_c
    ri_to_c = xBlock(struct('source', 'casper_library_misc/ri_to_c', 'name', 'ri_to_c'), ...
                            [], ...
                            {ROM_out1, ROM1_out1}, ...
                            {w});   
end

              
        




end

