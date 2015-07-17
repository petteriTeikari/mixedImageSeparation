# mixedImageSeparation

With Independent Component Analysis [1,2,3] variants FastICA (http://research.ics.aalto.fi/ica/fastica/) and arabica (https://launchpad.net/arabica, which is basically a robust extension of FastICA [4]). 

The idea is to blindly separate channels so that their statistical independence is maximized using the FastICA variant of Independent Component Analysis (ICA):

![ICA](https://dl.dropboxusercontent.com/u/6757026/githubFigures/ica_basicIllustration.png)


## References

[1] Hyvärinen A, Oja E. 2000. Independent component analysis: algorithms and applications. Neural Netw 13:411–430. http://dx.doi.org/10.1016/S0893-6080(00)00026-5.

[2] Bronstein AM, Bronstein MM, Zibulevsky M, Zeevi YY. 2005. Sparse ICA for blind separation of transmitted and reflected images. Int. J. Imaging Syst. Technol. 15:84–91. http://dx.doi.org/10.1002/ima.20042.

[3] Shlens J. 2014. A Tutorial on Independent Component Analysis. arXiv:1404.2986 [cs, stat]. http://arxiv.org/abs/1404.2986.

[4] Reyhani N, Ylipaavalniemi J, Vigário R, Oja E. 2012. Consistency and asymptotic normality of FastICA and bootstrap FastICA. Signal Processing 92. Latent Variable Analysis and Signal Separation:1767–1778. http://dx.doi.org/10.1016/j.sigpro.2011.11.025.


