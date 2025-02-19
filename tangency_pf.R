tangency.portfolio <-
  function(er,cov.mat,risk.free, shorts=TRUE)
  {
    call <- match.call()
    
    #
    # check for valid inputs
    #
    asset.names <- names(er)
    if(risk.free < 0)
      stop("Risk-free rate must be positive")
    er <- as.vector(er)
    cov.mat <- as.matrix(cov.mat)
    N <- length(er)
    if(N != nrow(cov.mat))
      stop("invalid inputs")
    if(any(diag(chol(cov.mat)) <= 0))
      stop("Covariance matrix not positive definite")
    # remark: could use generalized inverse if cov.mat is positive semi-definite
    # 
    # compute tangency portfolio
    #
    if(shorts==TRUE){
      cov.mat.inv <- solve(cov.mat)
      w.t <- cov.mat.inv %*% (er - risk.free) # tangency portfolio
      w.t <- as.vector(w.t/sum(w.t))          # normalize weights
    } else if(shorts==FALSE){
      Dmat <- 2*cov.mat
      dvec <- rep.int(0, N)
      er.excess <- er - risk.free
      Amat <- cbind(er.excess, diag(1,N))
      bvec <- c(1, rep(0,N))
      result <- quadprog::solve.QP(Dmat=Dmat,dvec=dvec,Amat=Amat,bvec=bvec,meq=1)
      w.t <- round(result$solution/sum(result$solution), 6)
    } else {
      stop("Shorts needs to be logical. For no-shorts, shorts=FALSE.")
    }
    
    names(w.t) <- asset.names
    er.t <- crossprod(w.t,er)
    sd.t <- sqrt(t(w.t) %*% cov.mat %*% w.t)
    tan.port <- list("call" = call,
                     "er" = as.vector(er.t),
                     "sd" = as.vector(sd.t),
                     "weights" = w.t)
    class(tan.port) <- "portfolio"
    return(tan.port)
  }