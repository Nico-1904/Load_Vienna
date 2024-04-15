%%Buldings
%-----------
wallLossdB = 10;
heightm = 50;
floorPlanX = [30,20,25,30,35,30]; % m
floorPlanY = [0 ,20,35,20,10,0 ]; % m
floorPlan = [floorPlanX; floorPlanY];

bu = blockages.Building(floorPlan, heightm, wallLossdB);

figure(1);
    title('building of type "blockages.Building"');
    grid on;
    transparency = 0.5;
    bu.plot(grey, transparency);
    bu.plotFloorPlan(tools.myColors.black);