//
//  MZMainViewController.h
//  Memz
//
//  Created by Bastien Falcou on 12/15/15.
//  Copyright © 2015 Falcou. All rights reserved.
//

#import "MZPageViewController.h"

typedef NS_ENUM(NSUInteger, MZMainViewControllerPages) {
	CHKMainViewControllerPageFeed,
	CHKMainViewControllerPagePolls,
	CHKMainViewControllerPageToBeDecided,
};

@interface MZMainViewController : MZPageViewController

@end
