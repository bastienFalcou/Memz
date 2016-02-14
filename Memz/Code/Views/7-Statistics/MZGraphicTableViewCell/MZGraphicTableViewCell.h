//
//  MZGraphicTableViewCell.h
//  Memz
//
//  Created by Bastien Falcou on 2/6/16.
//  Copyright © 2016 Falcou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MZGraphicView.h"

@interface MZGraphicTableViewCell : UITableViewCell

@property (strong, nonatomic) IBOutlet MZGraphicView *graphicView;

@end
