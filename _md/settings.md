The **settings tab** allows the user to customize methods to normalize and weight information layers. In this section the user can: choose between three normalization methods –reference, observe and standardize–; prioritize an indicator by assigning weights.

## Columns description
### normalization_method
Normalization method describe how data in different units is transformed into an adimensional index with values in the range 0 to 100. Options include: **reference**, **observe** and **standardize**. 

The **reference** method normalizes data according to the definition of minimum and maximum standards. Such standards are described in the *lowest_value* and *highest_value* columns in the table. Users can modify such columns according to their specific needs. Values below *lowest_value* are treated as zeros and values above *highest_value* are treated as 100. All the rest are normalized linearly in a scale from 0 to 100. 

The **observe** method normalizes data according to the minimum and maximum observed values. The minimum value is treated as zero, the maximum value is treated as 100 and all the rest are normalized linearly. If the **observe** method is selected, columns *lowest_value* and *highest_value* will be ignored. 

The **standardize** method is similar to the **observe** method. The difference is that the process is performed using the standard deviation of all observations in the layer. Read more about the method in the [scale R function](http://stat.ethz.ch/R-manual/R-devel/library/base/html/scale.html) documentation. 

### smaller_better
The column *smaller_better* describes whether the index should increase (or decrease) with higher (or lower) values in a layer. For example, if a user is mapping locations for a housing project, which minimize commuting time, it will be natural to expect that shorter distances to schools  are better than longer distances. In this example, smaller numbers are better, or in therms of the tool **smaller_better = TRUE**.

### weight
The *weight* column describes how relevant is a layer as compared to others. The tool will compute the weighted mean to aggregate all layers in a single index.

### default_on
The *default_on* column describes whether the layer shall be active on startup (TRUE) or not (FALSE). Values in the *default_on* column are defined by the data owner and final users can not modify settings on such column. 
