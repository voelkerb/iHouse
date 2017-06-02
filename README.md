# iHouse - A voice controlled, centralized, retrospective Smart Home System

Speech recognition in smart home systems has become popular in both, research and consumer areas. Therefore, this solution is based on an innovative concept for a modular, customizable, and voice-controlled smart home system. The system combines the advantages of distributed and centralized processing to enable a secure as well as highly modular platform and allows to add existing non-smart components retrospectively into the smart environment. To interact with the system in the most comfortable way - and in particular without additional devices like smartphones - voice-controlling was added as the means of choice. The task of speech recognition is partitioned into decentral Wake-Up-Word (WUW) recognition and central continuous speech recognition to enable flexibility while maintaining security. This is achieved utilizing a novel WUW algorithm suitable to be executed on small microcontrollers which uses Mel Frequency Cepstral Coefficients as well as Dynamic Time Warping.



# Why is not every home smart (yet)?
The reason that not every home use smart components has - at least in my opinion - 4 major reasons:

<img src="https://github.com/voelkerb/iHouse/blob/master/docu/Compatibility.jpg" width="100"> **1. Missing compatibility between existing products:** There are lots of different providers with different products on the market and nearly every provider is using its own protocol which hampers the compatibility of devices. 

<img src="https://github.com/voelkerb/iHouse/blob/master/docu/Security.jpg" width="100"> **2. Security:** People are affraid that personal information is leaked or that an attacker is able to control their homes as well.

<img src="https://github.com/voelkerb/iHouse/blob/master/docu/Retrospectivity.jpg" width="100"> **3. Retrospective use and affordability:** Existing equipment needs to be exchanged with new ones even if it is still working - like the recently bought Non-Smart-TV. This not only a question about affordability but also about sustainability.


<img src="https://github.com/voelkerb/iHouse/blob/master/docu/Flexibility.jpg" width="100"> **4. Flexibility and ease of use:** The last and main readon is the missing flexibility. The system should not require experts to install or later use it. Also you should not have to search for you Smartphone in the dark first in order to turn on the light.  


# System Overview
![alt text](https://github.com/voelkerb/iHouse/blob/master/docu/iHouseOverview.jpg)
