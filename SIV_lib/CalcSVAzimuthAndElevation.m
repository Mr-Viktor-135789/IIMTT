function [el, az] = CalcSVAzimuthAndElevation(xSV, ySV, zSV,...
    xUser,yUser,zUser)
    % calculation of pseudorange
    dX = xSV - xUser;
    dY = ySV - yUser;
    dZ = zSV - zUser;
    R = sqrt( dX^2 + dY^2 + dZ^2 );
    % calculation of elevation
    rp = sqrt( xUser^2 + yUser^2 + zUser^2 );
    scalar = ( xUser*dX + yUser*dY + zUser*dZ ) / ( rp*R );
    el = 0.5 * pi - acos(scalar);
    % calculation of azimuth
    rxy = sqrt(xUser^2 + yUser^2 );
    rxyz = rp;
    
    cosll = xUser / rxy;
    sinll = yUser / rxy;
    sintt = zUser / rxyz;
    
    xn1 = -sintt * cosll;
    xn2 = -sintt * sinll;
    xn3 = rxy / rxyz;
    
    p1 = xn1 * dX + xn2 * dY + xn3 * dZ;
    p2 = -sinll * dX + cosll * dY;
    
    az =  0.5 * pi - atan2(p1, p2);
    if az < 0
        az = 2*pi + az;
    end
end