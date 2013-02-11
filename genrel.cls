\pdfminorversion=4 % force pdf 1.4 output; http://tex.stackexchange.com/questions/95973/is-pdftex-1-40-13-outputting-malformed-pdfs

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{genrel}

\LoadClass[11pt]{book}
% Note that 11 pt does work with pdflatex, even though 11 pt is not one of the sizes
% of CM. I don't know whether it scales up 10 pt or scales down 12 pt, but anyway, it
% works.
%====================== counters =====================================================
\newcounter{dqctr}[subsection]
\newcounter{egctr}[chapter]
\newcounter{scctr}[chapter]
\newcounter{hwctr}[chapter]
%====================== packages =====================================================
\RequirePackage[leqno]{amsmath}
\RequirePackage{url,tensor,ifthen,learn-cmd-syntax,tikz}
\StartSaveCommands % for learn-cmd-syntax
%====================== tikz stuff for birdtracks =====================================================
\pgfdeclarelayer{nodelayer}
\pgfdeclarelayer{edgelayer}
\pgfsetlayers{edgelayer,nodelayer,main}
\tikzstyle{plain}=[rectangle,fill=none,draw=none,scale=1.0,inner sep=1.8pt] % circle also works
\tikzstyle{boxed}=[rectangle,fill=none,draw=black,scale=1.0,inner sep=1.8pt] % circle also works
\tikzstyle{arrow}=[draw=black,arrows=-latex]
\newcommand{\birdvec}[1]{%
\begin{tikzpicture}[baseline=(n1.base),thick]
  \begin{pgfonlayer}{nodelayer}
    \node [style=plain] (n0) at (0, 0) {};
    \node [style=plain] (n1) at +(1.5em, 0) {$#1$};
  \end{pgfonlayer}
  \begin{pgfonlayer}{edgelayer}
    \draw [style=arrow] (n0) to (n1);
  \end{pgfonlayer}
\end{tikzpicture}
}
\newcommand{\birddualvec}[1]{%
\begin{tikzpicture}[baseline=(n0.base),thick]
  \begin{pgfonlayer}{nodelayer}
    \node [style=plain] (n0) at (0, 0) {$#1$};
    \node [style=plain] (n1) at +(1.5em, 0) {};
  \end{pgfonlayer}
  \begin{pgfonlayer}{edgelayer}
    \draw [style=arrow] (n0) to (n1);
  \end{pgfonlayer}
\end{tikzpicture}
}
\newcommand{\birdscalarproduct}[2]{
\begin{tikzpicture}[baseline=(n0.base),thick]
  \begin{pgfonlayer}{nodelayer}
    \node [style=plain] (n0) at (0, 0) {$#1$};
    \node [style=plain] (n1) at +(1.8em, 0) {$#2$};
  \end{pgfonlayer}
  \begin{pgfonlayer}{edgelayer}
    \draw [style=arrow] (n0) to (n1);
  \end{pgfonlayer}
\end{tikzpicture}
}
\newcommand{\birdflipscalarproduct}[2]{
\begin{tikzpicture}[baseline=(n0.base),thick]
  \begin{pgfonlayer}{nodelayer}
    \node [style=plain] (n0) at (0, 0) {$#2$};
    \node [style=plain] (n1) at +(1.8em, 0) {$#1$};
  \end{pgfonlayer}
  \begin{pgfonlayer}{edgelayer}
    \draw [style=arrow] (n1) to (n0);
  \end{pgfonlayer}
\end{tikzpicture}
}

%====================== pull in sub-packages =====================================================
\RequirePackage{lmlanguage,lmlayout,lmcommon,lmfigs,lmenvironments}

%=====================================================================================
% In DP, we use italics for figref, but in LM that would look too much like an algebra
% symbol, so no italics.
\newcommand{\formatfigref}[1]{#1}

% titlesec stuff:
\titleformat{\chapter}[display]
    {\normalfont\huge\bfseries\sffamily\raggedright}{Chapter \thechapter}{0mm}
    {\Huge}
\newcommand{\normalsectiontitleformat}{
  \titleformat{\section}
    {\normalfont\Large\bfseries\sffamily\raggedright}{\showsecnum{\thesection}}{0.6em}{}
}
\normalsectiontitleformat
\titleformat{\subsection}
  {\normalfont\normalsize\bfseries\sffamily\raggedright\protect\sansmath}{\lmserifmath\showsecnum{\thesubsection}}{0.6em}{}
\titleformat{\subsubsection}
  {\normalfont\normalsize\slshape\raggedright}{\thesubsubsection}{1em}{}
%-------------------- sections and subsections -------------------------
% (chapter stuff is in lmfigs.cls, since it contains a lot of stuff for figures)
  \newcommand{\mysection}[2][4]{\pagebreak[#1]%
	\section{#2}\myeqnspacing%
        \setcounter{figctr}{0}
        \setcounter{dqctr}{0}% gets done automatically for subsections, but I need to do it explicitly for sections that have no subsections
  }
  \newcommand{\myoptionalsection}[2][4]{\pagebreak[#1]%
	\section{$\star$ #2}\myeqnspacing}
  \newcommand{\mysubsection}[2][3]{\pagebreak[#1]\subsection{#2}}
  \newcommand{\mysubsectionnotoc}[2][3]{\pagebreak[#1]\subsection*{#2}}

\StopSaveCommands % for learn-cmd-syntax
\WriteSaveCommands  % for learn-cmd-syntax
