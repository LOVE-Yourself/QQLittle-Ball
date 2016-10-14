//
//  BageValue.m
//  08-QQ粘性布局
//
//  Created by xiaomage on 15/9/29.
//  Copyright (c) 2015年 xiaomage. All rights reserved.
//

#import "BageValue.h"

@interface BageValue()

@property (nonatomic, weak)  UIView *smallCircle;
@property (nonatomic, weak)  CAShapeLayer *shap;


@end
@implementation BageValue


-(void)awakeFromNib{
    [self setUP];
}

-(instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self setUP];
    }
    return self;
}



-(CAShapeLayer *)shap{

    if (_shap == nil) {
        //形状图层
        //它可以根据一个路径生成一个形状.
        CAShapeLayer *shap = [CAShapeLayer layer];
        //设置形状的填充颜色
        shap.fillColor = [UIColor redColor].CGColor;
        _shap = shap;
        [self.superview.layer insertSublayer:shap atIndex:0];
    }
    return _shap;

}

//初始化
- (void)setUP{
    //设置圆角
    self.layer.cornerRadius = self.bounds.size.width * 0.5;
    //设置背景颜色
    [self setBackgroundColor:[UIColor redColor]];
    [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.titleLabel.font = [UIFont systemFontOfSize:12];
    
    //添加手势
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [self addGestureRecognizer:pan];
    
    //添加小圆
    UIView *smallCircle = [[UIView alloc] init];
    smallCircle.frame = self.frame;
    smallCircle.backgroundColor = self.backgroundColor;
    smallCircle.layer.cornerRadius = self.layer.cornerRadius;
    self.smallCircle = smallCircle;
    [self.superview insertSubview:smallCircle belowSubview:self];
    
    
    
}


//计算两个圆之间的距离
- (CGFloat)distanceWithSmallCircle:(UIView *)smallCircle bigCircle:(UIView *)bigCircle{
    
    //X轴偏移量
    CGFloat offsetX = bigCircle.center.x - smallCircle.center.x;
    //Y轴偏移量
    CGFloat offsetY = bigCircle.center.y - smallCircle.center.y;
    
   return  sqrtf(offsetX * offsetX + offsetY * offsetY);

}

//根据两个圆设置一个不规的路径
- (UIBezierPath *)pathWithSmallCircle:(UIView *)smallCircle bigCircle:(UIView *)bigCircle{
    
    CGFloat x1 = smallCircle.center.x;
    CGFloat y1 = smallCircle.center.y;
    
    CGFloat x2 = bigCircle.center.x;
    CGFloat y2 = bigCircle.center.y;
    
    CGFloat d = [self distanceWithSmallCircle:smallCircle bigCircle:self];
    
    if (d <= 0) {
        return nil;
    }
    
    
    CGFloat cosθ = (y2 - y1) / d;
    CGFloat sinθ = (x2 - x1) / d;
    
    CGFloat r1 = smallCircle.bounds.size.width * 0.5;
    CGFloat r2 = bigCircle.bounds.size.width * 0.5;
    
    CGPoint pointA = CGPointMake(x1 - r1 * cosθ, y1 + r1 * sinθ);
    CGPoint pointB = CGPointMake(x1 + r1 * cosθ, y1 - r1 * sinθ);
    CGPoint pointC = CGPointMake(x2 + r2 * cosθ, y2 - r2 * sinθ);
    CGPoint pointD = CGPointMake(x2 - r2 * cosθ, y2 + r2 * sinθ);
    CGPoint pointO = CGPointMake(pointA.x + d * 0.5 * sinθ, pointA.y + d * 0.5 * cosθ);
    CGPoint pointP = CGPointMake(pointB.x + d * 0.5 * sinθ, pointB.y + d * 0.5 * cosθ);
    
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    //AB
    [path moveToPoint:pointA];
    [path addLineToPoint:pointB];
    //BC(曲线)
    [path addQuadCurveToPoint:pointC controlPoint:pointP];
    //CD
    [path addLineToPoint:pointD];
    //DA(曲线)
    [path addQuadCurveToPoint:pointA controlPoint:pointO];
    
    return path;

}


- (void)pan:(UIPanGestureRecognizer *)pan{

    //frame,center,transform.
    
    //移动.
    CGPoint transP = [pan translationInView:self];
    //修改transform值,并没有去修改center,它修改的frame
//    self.transform = CGAffineTransformTranslate(self.transform, transP.x, transP.y);
    
     CGPoint center =  self.center;
     center.x += transP.x;
     center.y += transP.y;
     self.center = center;
    NSLog(@"-----%f%f",transP.x,transP.y);
    //复位
    [pan setTranslation:CGPointZero inView:self];
    //两个圆之间的距离
    CGFloat distance = [self distanceWithSmallCircle:self.smallCircle bigCircle:self];
    
    //让小圆的半径减去距离的比例
    //获取小圆的半径
    CGFloat smallR = self.bounds.size.width * 0.5;
    smallR = smallR - distance / 10.0;
    //要重设置小圆的尺寸
    self.smallCircle.bounds = CGRectMake(0, 0, smallR * 2, smallR * 2);
    //重新设置小圆的圆角
    self.smallCircle.layer.cornerRadius = smallR;
    

    //不规则的路径.
    
    //如果小圆显示的时候再创建
    if(self.smallCircle.hidden == NO){
        UIBezierPath *path = [self pathWithSmallCircle:self.smallCircle bigCircle:self];
        self.shap.path = path.CGPath;
    }
    

    //如果两个圆之间的距离超过某个范围.让小圆隐藏,shap移除
    if(distance > 60){
        self.smallCircle.hidden = YES;
        [self.shap removeFromSuperlayer];
    }
    //当手指松开时,如果发现两个圆之间距离小于某个值时,大圆复位.
    if(pan.state == UIGestureRecognizerStateEnded){
     //如果发现两个圆之间距离小于某个值时,大圆复位.
        if (distance < 60) {
            //移除形状
            [self.shap removeFromSuperlayer];
            
            //添加一个弹性动画
            [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:0.2 initialSpringVelocity:0 options:UIViewAnimationOptionCurveLinear animations:^{
    
                //大圆复位.
                self.center = self.smallCircle.center;
            } completion:^(BOOL finished) {
                //让小圆显示
                self.smallCircle.hidden = NO;
            }];
       
           
        }else{
            //如果发现两个圆之间距离大于某个值时,播放动画,按钮从父控件当中移.
            
            //添加一个UIImageView
            UIImageView *imageV = [[UIImageView alloc] initWithFrame:self.bounds];
            
            NSMutableArray *imageArray = [NSMutableArray array];
            for (int i = 0; i < 8; ++i) {
                NSString *imageName = [NSString stringWithFormat:@"%d",i + 1];
                UIImage *image = [UIImage imageNamed:imageName];
                [imageArray addObject:image];
            }
        
            imageV.animationImages = imageArray;
            //设置动画的执行时长
            [imageV setAnimationDuration:1];
            //开始动画
            [imageV startAnimating];
            [self addSubview:imageV];
            
            //一秒钟后.把当前的按钮从父控件当中移.
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                //把当前的按钮从父控件当中移.
                [self removeFromSuperview];
            });
            
            
        }
    
    }
   
    
    
    
}


//取消高亮状态
-(void)setHighlighted:(BOOL)highlighted{
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
