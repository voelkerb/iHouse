//
//  PlotViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 04/08/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "PlotViewController.h"



@interface PlotViewController ()

@end

@implementation PlotViewController

@synthesize graphView;
@synthesize graph;

@synthesize minimumValueForXAxis;
@synthesize maximumValueForXAxis;
@synthesize minimumValueForYAxis;
@synthesize maximumValueForYAxis;

@synthesize majorIntervalLengthForX;
@synthesize majorIntervalLengthForY;
@synthesize dataPoints;

@synthesize zoomAnnotation;
@synthesize dragStart;
@synthesize dragEnd;
@synthesize plots;
@synthesize plotData;

-(id)init {
  if (self = [super init]) {
    dataPoints     = [[NSMutableArray alloc] init];
    zoomAnnotation = nil;
    dragStart      = CGPointZero;
    dragEnd        = CGPointZero;
    plots = [[NSMutableArray alloc] init];
    plotData = [[NSMutableArray alloc] init];
    
    
    minimumValueForXAxis = MAXFLOAT;
    maximumValueForXAxis = -MAXFLOAT;
    
    minimumValueForYAxis = MAXFLOAT;
    maximumValueForYAxis = -MAXFLOAT;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self loadGraph];
}

-(void)viewDidLayout {
}

/*
 * Load a graph into the CPTXGraphView
 */
- (void)loadGraph {
  // Create graph from theme
  graph = [[CPTXYGraph alloc] initWithFrame:graphView.frame];
  // Load and apply theme
  CPTTheme *theme      = [CPTTheme themeNamed:kCPTPlainBlackTheme];
  [graph applyTheme:theme];
  
  self.graphView.hostedGraph = graph;
  
  
  graph.paddingLeft   = 0.0;
  graph.paddingTop    = 0.0;
  graph.paddingRight  = 0.0;
  graph.paddingBottom = 0.0;
  
  graph.plotAreaFrame.paddingLeft   = 65.0;
  graph.plotAreaFrame.paddingTop    = 10.0;
  graph.plotAreaFrame.paddingRight  = 10.0;
  graph.plotAreaFrame.paddingBottom = 70.0;
  
  graph.plotAreaFrame.plotArea.fill = graph.plotAreaFrame.fill;
  
  CPTMutableLineStyle *borderLineStyle = [CPTMutableLineStyle lineStyle];
  borderLineStyle.lineWidth = 1.0f;
  borderLineStyle.lineColor = [CPTColor whiteColor];
  //graph.plotAreaFrame.plotArea.borderLineStyle = borderLineStyle;
  graph.plotAreaFrame.plotArea.cornerRadius    = 0.0;
  graph.plotAreaFrame.plotArea.masksToBorder   = NO;
  graph.plotAreaFrame.borderLineStyle = nil;
  graph.plotAreaFrame.cornerRadius    = 0.0;
  graph.plotAreaFrame.masksToBorder   = NO;
  graph.fill   = [CPTFill fillWithColor:[CPTColor clearColor]];;
  graph.plotAreaFrame.fill   = [CPTFill fillWithColor:[CPTColor clearColor]];;
  graph.plotAreaFrame.plotArea.fill   = [CPTFill fillWithColor:[CPTColor clearColor]];;
  
}


#pragma mark -
#pragma mark Data loading methods

-(void)removeAllPlots {
  [self.plots removeAllObjects];
  [self.plotData removeAllObjects];
}

-(BOOL)loadPlotNamed:(NSString*)name withTimeData:(NSArray *)xData yData:(NSArray *)yData lineColor:(NSColor*)lineColor timeInterval:(NSTimeInterval)timeInterval {
  NSLog(@"Got data to load plot, x: %li, y: %li", [xData count], [yData count]);
  
  if ([xData count] != [yData count]) return false;
  double minX = minimumValueForXAxis;
  double maxX = maximumValueForXAxis;
  
  double minY = minimumValueForYAxis;
  double maxY = maximumValueForYAxis;
  
  NSMutableArray<NSDictionary *> *newData = [[NSMutableArray alloc] init];
  
  for (size_t i = 0; i < [xData count]; i++) {
    double xValue = [xData[i] doubleValue];
    double yValue = [yData[i] doubleValue];
    if ( xValue < minX ) {
      minX = xValue;
    }
    if ( xValue > maxX ) {
      maxX = xValue;
    }
    if ( yValue < minY ) {
      minY = yValue;
    }
    if ( yValue > maxY ) {
      maxY = yValue;
    }
    
    
    [newData addObject:@{ @"x": @(xValue),
                          @"y": @(yValue) }];
  }
  [self.plotData addObject:newData];
  
  self.dataPoints = newData;
  
  double intervalX = (maxX - minX) / 5.0;
  /*
  if ( intervalX > 0.0 ) {
    intervalX = pow( 1.0, ceil( log10(intervalX) ) );
  }*/
  self.majorIntervalLengthForX = intervalX;
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  
  [dateFormatter setDateFormat:@"HH:mm"];
  if (timeInterval >= 60*60*24) {
    [dateFormatter setDateFormat:@"dd/MM"];
  }
  [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
  self.majorIntervalLengthForX = timeInterval;
  
  double intervalY = (maxY - minY) / 3.0;
  /*
  if ( intervalY > 0.0 ) {
    intervalY = pow( 1.0, ceil( log10(intervalY) ) );
   }*/
  self.majorIntervalLengthForY = intervalY;
  
  //minX = floor(minX / intervalX) * intervalX;
  minY = floor(minY / intervalY) * intervalY;
  
  self.minimumValueForXAxis = minX;
  self.maximumValueForXAxis = maxX;
  self.minimumValueForYAxis = minY;
  self.maximumValueForYAxis = maxY;
  
  NSLog(@"x: min: %.2f, max: %.2f", minX, maxX);
  NSLog(@"y: min: %.2f, max: %.2f", minY, maxY);
  
  // Setup plot space
  CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
  plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:@(self.minimumValueForXAxis)
                                                  length:@((self.maximumValueForXAxis - self.minimumValueForXAxis))];
  plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:@(self.minimumValueForYAxis)
                                                  length:@(ceil( (self.maximumValueForYAxis - self.minimumValueForYAxis) / self.majorIntervalLengthForY ) * self.majorIntervalLengthForY)];
  
  // this allows the plot to respond to mouse events
  [plotSpace setDelegate:self];
  [plotSpace setAllowsUserInteraction:YES];
  
  
  CPTMutableLineStyle *majorGridLineStyle = [CPTMutableLineStyle lineStyle];
  majorGridLineStyle.lineWidth = 2.0f;
  majorGridLineStyle.lineColor = [CPTColor whiteColor];
  
  CPTMutableTextStyle *whiteTextStyle = [CPTMutableTextStyle textStyle];
  whiteTextStyle.color = [CPTColor whiteColor];
  whiteTextStyle.fontSize = 12.0;
  
  CPTXYAxisSet *axisSet = (CPTXYAxisSet *)graph.axisSet;
  CPTXYAxis *x = axisSet.xAxis;
  
  x.labelingPolicy = CPTAxisLabelingPolicyFixedInterval;
  x.majorIntervalLength = @(majorIntervalLengthForX);
  
  //Label time Format:
  CPTTimeFormatter *timeFormatter = [[CPTTimeFormatter alloc] initWithDateFormatter:dateFormatter];
  x.labelFormatter   = timeFormatter;

  
  x.minorTicksPerInterval = 2;
  x.minorTickLineStyle = x.majorTickLineStyle;
  x.majorIntervalLength   = @(self.majorIntervalLengthForX);
  x.labelOffset           = 5.0;
  x.axisConstraints       = [CPTConstraints constraintWithLowerOffset:0.0];
  x.axisLineStyle = majorGridLineStyle;
  x.titleTextStyle = whiteTextStyle;
  //x.title = @"Date/Time";
  x.titleOffset = 30.0f;
  CPTXYAxis *y = axisSet.yAxis;
  y.minorTicksPerInterval = 2;
  y.minorTickLineStyle = y.majorTickLineStyle;
  y.majorIntervalLength   = @(self.majorIntervalLengthForY);
  y.labelOffset           = 5.0;
  y.axisConstraints       = [CPTConstraints constraintWithLowerOffset:0.0];
  y.axisLineStyle = majorGridLineStyle;
  y.titleTextStyle = whiteTextStyle;
  y.title = name;
  y.titleOffset = 45.0f;
  
  // Create the main plot for the delimited data
  CPTScatterPlot *dataSourceLinePlot = [[CPTScatterPlot alloc] initWithFrame:graph.bounds];
  dataSourceLinePlot.identifier = name;
  
  CPTMutableLineStyle *lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];
  lineStyle.lineWidth              = 1.0;
  CPTColor *theLineColor = [CPTColor colorWithCGColor:[lineColor CGColor]];
  lineStyle.lineColor              = theLineColor;
  dataSourceLinePlot.dataLineStyle = lineStyle;
  
  dataSourceLinePlot.dataSource = self;
  
  
  [self.plots addObject:dataSourceLinePlot];
  [graph addPlot:dataSourceLinePlot];
  
  
  return YES;
}

#pragma mark -
#pragma mark Zoom Methods

-(IBAction)zoomIn:(id)sender {
  CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
  CPTPlotArea *plotArea     = self.graph.plotAreaFrame.plotArea;
  
  // convert the dragStart and dragEnd values to plot coordinates
  CGPoint dragStartInPlotArea = [self.graph convertPoint:self.dragStart toLayer:plotArea];
  CGPoint dragEndInPlotArea   = [self.graph convertPoint:self.dragEnd toLayer:plotArea];
  
  double start[2], end[2];
  
  // obtain the datapoints for the drag start and end
  [plotSpace doublePrecisionPlotPoint:start numberOfCoordinates:2 forPlotAreaViewPoint:dragStartInPlotArea];
  [plotSpace doublePrecisionPlotPoint:end numberOfCoordinates:2 forPlotAreaViewPoint:dragEndInPlotArea];
  
  // recalculate the min and max values
  self.minimumValueForXAxis = MIN(start[CPTCoordinateX], end[CPTCoordinateX]);
  self.maximumValueForXAxis = MAX(start[CPTCoordinateX], end[CPTCoordinateX]);
  self.minimumValueForYAxis = MIN(start[CPTCoordinateY], end[CPTCoordinateY]);
  self.maximumValueForYAxis = MAX(start[CPTCoordinateY], end[CPTCoordinateY]);
  
  // now adjust the plot range and axes
  plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:@(self.minimumValueForXAxis)
                                                  length:@(self.maximumValueForXAxis - self.minimumValueForXAxis)];
  plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:@(self.minimumValueForYAxis)
                                                  length:@(self.maximumValueForYAxis - self.minimumValueForYAxis)];
  
  CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
  axisSet.xAxis.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
  axisSet.yAxis.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
}

-(IBAction)zoomOut:(id)sender {
  double minX = MAXFLOAT;
  double maxX = -MAXFLOAT;
  
  double minY = MAXFLOAT;
  double maxY = -MAXFLOAT;
  
  // get the ful range min and max values
  for ( int i = 0; i < [plotData count]; i++ ) {
    NSArray *theDataPoints = [plotData objectAtIndex:i];
    for ( NSDictionary<NSString *, NSNumber *> *xyValues in theDataPoints ) {
      double xVal = [xyValues[@"x"] doubleValue];
      
      minX = fmin(xVal, minX);
      maxX = fmax(xVal, maxX);
      
      double yVal = [xyValues[@"y"] doubleValue];
      
      minY = fmin(yVal, minY);
      maxY = fmax(yVal, maxY);
    }
  }
  
  double intervalX = self.majorIntervalLengthForX;
  double intervalY = self.majorIntervalLengthForY;
  
  //minX = floor(minX / intervalX) * intervalX;
  minY = floor(minY / intervalY) * intervalY;
  
  self.minimumValueForXAxis = minX;
  self.maximumValueForXAxis = maxX;
  self.minimumValueForYAxis = minY;
  self.maximumValueForYAxis = maxY;
  
  /*
   if ( intervalY > 0.0 ) {
   intervalY = pow( 1.0, ceil( log10(intervalY) ) );
   }*/
  self.majorIntervalLengthForY = (maxY - minY) / 3.0;;
  

  // now adjust the plot range and axes
  CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
  
  plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:@(self.minimumValueForXAxis)
                                                  length:@(self.maximumValueForXAxis - self.minimumValueForXAxis)];
  plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:@(self.minimumValueForYAxis)
                                                  length:@(self.maximumValueForYAxis - self.minimumValueForYAxis)];
  CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
  axisSet.xAxis.labelingPolicy = CPTAxisLabelingPolicyFixedInterval;
  axisSet.yAxis.labelingPolicy = CPTAxisLabelingPolicyFixedInterval;
}

#pragma mark -
#pragma mark PDF / image export

-(IBAction)exportToPDF:(id)sender
{
  NSSavePanel *pdfSavingDialog = [NSSavePanel savePanel];
  
  [pdfSavingDialog setAllowedFileTypes:@[@"pdf"]];
  
  if ( [pdfSavingDialog runModal] == NSModalResponseOK ) {
    NSData *dataForPDF = [self.graph dataForPDFRepresentationOfLayer];
    
    NSURL *url = [pdfSavingDialog URL];
    if ( url ) {
      [dataForPDF writeToURL:url atomically:NO];
    }
  }
}

-(IBAction)exportToPNG:(id)sender
{
  NSSavePanel *pngSavingDialog = [NSSavePanel savePanel];
  
  [pngSavingDialog setAllowedFileTypes:@[@"png"]];
  
  if ( [pngSavingDialog runModal] == NSModalResponseOK ) {
    NSImage *image            = [self.graph imageOfLayer];
    NSData *tiffData          = [image TIFFRepresentation];
    NSBitmapImageRep *tiffRep = [NSBitmapImageRep imageRepWithData:tiffData];
    NSData *pngData           = [tiffRep representationUsingType:NSPNGFileType properties:[NSDictionary dictionary]];
    
    NSURL *url = [pngSavingDialog URL];
    if ( url ) {
      [pngData writeToURL:url atomically:NO];
    }
  }
}

#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
  for (int i = 0; i < [plots count]; i++) {
    CPTPlot *thePlot = (CPTPlot *)[plots objectAtIndex:i];
    if ([plot isEqualTo: thePlot]) {
      return [[plotData objectAtIndex:i] count];
    }
  }
  return 0;//self.dataPoints.count;
}

-(id)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
  NSString *key = (fieldEnum == CPTScatterPlotFieldX ? @"x" : @"y");
  
  for (int i = 0; i < [plots count]; i++) {
    CPTPlot *thePlot = (CPTPlot *)[plots objectAtIndex:i];
    if ([plot isEqualTo: thePlot]) {
      return [plotData objectAtIndex:i][index][key];
    }
  }
  
  return 0;//self.dataPoints[index][key];
}

#pragma mark -
#pragma mark Plot Space Delegate Methods

-(BOOL)plotSpace:(CPTPlotSpace *)space shouldHandlePointingDeviceDraggedEvent:(id)event atPoint:(CGPoint)interactionPoint
{
  CPTPlotSpaceAnnotation *annotation = self.zoomAnnotation;
  
  if ( annotation ) {
    CPTPlotArea *plotArea = self.graph.plotAreaFrame.plotArea;
    CGRect plotBounds     = plotArea.bounds;
    
    // convert the dragStart and dragEnd values to plot coordinates
    CGPoint dragStartInPlotArea = [self.graph convertPoint:self.dragStart toLayer:plotArea];
    CGPoint dragEndInPlotArea   = [self.graph convertPoint:interactionPoint toLayer:plotArea];
    
    // create the dragrect from dragStart to the current location
    CGFloat endX      = MAX( MIN( dragEndInPlotArea.x, CGRectGetMaxX(plotBounds) ), CGRectGetMinX(plotBounds) );
    CGFloat endY      = MAX( MIN( dragEndInPlotArea.y, CGRectGetMaxY(plotBounds) ), CGRectGetMinY(plotBounds) );
    CGRect borderRect = CGRectMake( dragStartInPlotArea.x, dragStartInPlotArea.y,
                                   (endX - dragStartInPlotArea.x),
                                   (endY - dragStartInPlotArea.y) );
    
    annotation.contentAnchorPoint = CGPointMake(dragEndInPlotArea.x >= dragStartInPlotArea.x ? 0.0 : 1.0,
                                                dragEndInPlotArea.y >= dragStartInPlotArea.y ? 0.0 : 1.0);
    annotation.contentLayer.frame = borderRect;
  }
  
  return NO;
}

-(BOOL)plotSpace:(CPTPlotSpace *)space shouldHandlePointingDeviceDownEvent:(id)event atPoint:(CGPoint)interactionPoint
{
  if ( !self.zoomAnnotation ) {
    self.dragStart = interactionPoint;
    
    CPTPlotArea *plotArea       = self.graph.plotAreaFrame.plotArea;
    CGPoint dragStartInPlotArea = [self.graph convertPoint:self.dragStart toLayer:plotArea];
    
    if ( CGRectContainsPoint(plotArea.bounds, dragStartInPlotArea) ) {
      // create the zoom rectangle
      // first a bordered layer to draw the zoomrect
      CPTBorderedLayer *zoomRectangleLayer = [[CPTBorderedLayer alloc] initWithFrame:CGRectNull];
      
      CPTMutableLineStyle *lineStyle = [CPTMutableLineStyle lineStyle];
      lineStyle.lineColor                = [CPTColor darkGrayColor];
      lineStyle.lineWidth                = 1.0;
      zoomRectangleLayer.borderLineStyle = lineStyle;
      
      CPTColor *transparentFillColor = [[CPTColor blueColor] colorWithAlphaComponent:0.2];
      zoomRectangleLayer.fill = [CPTFill fillWithColor:transparentFillColor];
      
      double start[2];
      [self.graph.defaultPlotSpace doublePrecisionPlotPoint:start numberOfCoordinates:2 forPlotAreaViewPoint:dragStartInPlotArea];
      CPTNumberArray *anchorPoint = @[@(start[CPTCoordinateX]),
                                     @(start[CPTCoordinateY])];
      
      // now create the annotation
      CPTPlotSpace *defaultSpace = self.graph.defaultPlotSpace;
      if ( defaultSpace ) {
        CPTPlotSpaceAnnotation *annotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:defaultSpace anchorPlotPoint:anchorPoint];
        annotation.contentLayer = zoomRectangleLayer;
        self.zoomAnnotation     = annotation;
        
        [self.graph.plotAreaFrame.plotArea addAnnotation:annotation];
      }
    }
  }
  
  return NO;
}

-(BOOL)plotSpace:(CPTPlotSpace *)space shouldHandlePointingDeviceUpEvent:(id)event atPoint:(CGPoint)interactionPoint
{
  CPTPlotSpaceAnnotation *annotation = self.zoomAnnotation;
  
  if ( annotation ) {
    self.dragEnd = interactionPoint;
    
    // double-click to completely zoom out
    if ( [event clickCount] == 2 ) {
      CPTPlotArea *plotArea     = self.graph.plotAreaFrame.plotArea;
      CGPoint dragEndInPlotArea = [self.graph convertPoint:interactionPoint toLayer:plotArea];
      
      if ( CGRectContainsPoint(plotArea.bounds, dragEndInPlotArea) ) {
        [self zoomOut:self];
      }
    }
    else if ( !CGPointEqualToPoint(self.dragStart, self.dragEnd) ) {
      // no accidental drag, so zoom in
      [self zoomIn:self];
    }
    
    // and we're done with the drag
    [self.graph.plotAreaFrame.plotArea removeAnnotation:annotation];
    self.zoomAnnotation = nil;
    
    self.dragStart = CGPointZero;
    self.dragEnd   = CGPointZero;
  }
  
  return NO;
}

-(BOOL)plotSpace:(CPTPlotSpace *)space shouldHandlePointingDeviceCancelledEvent:(id)event atPoint:(CGPoint)interactionPoint
{
  CPTPlotSpaceAnnotation *annotation = self.zoomAnnotation;
  
  if ( annotation ) {
    [self.graph.plotAreaFrame.plotArea removeAnnotation:annotation];
    self.zoomAnnotation = nil;
    
    self.dragStart = CGPointZero;
    self.dragEnd   = CGPointZero;
  }
  
  return NO;
}



@end
