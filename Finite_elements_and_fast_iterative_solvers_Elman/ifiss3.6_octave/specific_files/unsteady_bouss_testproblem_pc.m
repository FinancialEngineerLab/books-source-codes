%UNSTEADY_BOUSS_TESTPROBLEM_PC sets up Boussinesq flow problem
%   IFISS scriptfile: DJS;  9 May 2012.
% Copyright (c) 2012 D.J. Silvester, M.L. Mihajlovic.
gohome
clear variables, clear functions
fprintf('\nSpecification of unsteady Boussinesq problem.\n')
fprintf('\nchoose specific example');
fprintf('\n     1  Bottom heated cavity')
fprintf('\n     2  Laterally heated cavity');
fprintf('\n     3  Bottom heated forward step');
bsn = default('',2);
if bsn==1
system('copy .\boussinesq_flow\test_problems\bottom_bc.m .\diffusion\specific_bc.m');
system('copy .\stokes_flow\test_problems\no_flow.m .\stokes_flow\specific_flow.m');
system('copy .\diffusion\test_problems\zero_bc.m .\stokes_flow\stream_bc.m');
cavity_bouss, unsteady_bouss
elseif bsn==2
system('copy .\boussinesq_flow\test_problems\lateral_bc.m .\diffusion\specific_bc.m');
system('copy .\stokes_flow\test_problems\no_flow.m .\stokes_flow\specific_flow.m');
system('copy .\diffusion\test_problems\zero_bc.m .\stokes_flow\stream_bc.m');
cavity_bouss, unsteady_bouss
elseif bsn==3
system('copy .\timestepping\test_problems\heat3_bc.m .\diffusion\specific_bc.m');
system('copy .\stokes_flow\test_problems\backwardstep_flow.m .\stokes_flow\specific_flow.m');
system('copy .\stokes_flow\test_problems\backwardstep_bc.m .\stokes_flow\stream_bc.m');
step_bouss, unsteady_step_bouss
else
   error('reference problem datafile not found!')
end
