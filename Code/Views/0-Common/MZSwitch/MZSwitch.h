//
//  MZSwitch.h
//  Memz
//
//  Created by Bastien Falcou on 1/7/15.
//  Copyright (c) 2015 Fueled. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE

/* This UISwitch subclass defines or redifines useful UI properties for your switches:
 *
 *   - onTintColor: color of the background when the switch is On. If set to nil, the default color (green) will be applied.
 *   - offTintColor: color of the background when the switch is Off. If set to nil, the default color (clearColor) will be applied.
 *
 *   - onImage: image in the background when the switch is On. If "onTintColor" is defined, the image will override the color 
 *       (color won't be seen). If set to nil, the previous image will be deleted and the onTintColor will be seen instead.
 *   - offImage: image in the background when the switch is Off. if "offTintColor" is defined, the image will override the color 
 *       (color won't be seen). If set to nil, the previous image will be deleted and the offTintColor will be seen instead.
 */

@interface MZSwitch : UISwitch

@property (nonatomic, strong) IBInspectable UIColor* offTintColor;  // background color when switch turned off

@end
