//
//  PlotViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 04/08/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CorePlot/CorePlot.h>

@interface PlotViewController : NSViewController<CPTPlotDataSource, CPTPlotSpaceDelegate>

@property (nonatomic, readwrite, strong) IBOutlet CPTGraphHostingView *graphView;
@property (nonatomic, readwrite, strong) CPTXYGraph *graph;
@property (nonatomic, readwrite, strong) NSMutableArray *plots;
@property (nonatomic, readwrite, strong) NSMutableArray *plotData;

@property (nonatomic, readwrite, assign) double minimumValueForXAxis;
@property (nonatomic, readwrite, assign) double maximumValueForXAxis;
@property (nonatomic, readwrite, assign) double minimumValueForYAxis;
@property (nonatomic, readwrite, assign) double maximumValueForYAxis;
@property (nonatomic, readwrite, assign) double majorIntervalLengthForX;
@property (nonatomic, readwrite, assign) double majorIntervalLengthForY;
@property (nonatomic, readwrite, strong) NSArray<NSDictionary *> *dataPoints;

@property (nonatomic, readwrite, strong) CPTPlotSpaceAnnotation *zoomAnnotation;
@property (nonatomic, readwrite, assign) CGPoint dragStart;
@property (nonatomic, readwrite, assign) CGPoint dragEnd;

// Load a new plot to the existing graph
-(BOOL)loadPlotNamed:(NSString*)name withTimeData:(NSArray *)xData yData:(NSArray *)yData lineColor:(NSColor*)lineColor timeInterval:(NSTimeInterval)timeInterval;
-(void)removeAllPlots;

-(IBAction)zoomIn:(id)sender;
-(IBAction)zoomOut:(id)sender;


// PDF / image export
-(IBAction)exportToPDF:(id)sender;
-(IBAction)exportToPNG:(id)sender;


@end
