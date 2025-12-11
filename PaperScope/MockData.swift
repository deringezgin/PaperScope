import Foundation

struct MockData {
    static let papers: [Paper] = [
        Paper(
            id: UUID(),
            title: "Attention Is All You Need",
            authors: "Ashish Vaswani, Noam Shazeer, Niki Parmar, et al.",
            summary: "The dominant sequence transduction models are based on complex recurrent or convolutional neural networks that include an encoder and a decoder. The best performing models also connect the encoder and decoder through an attention mechanism. We propose a new simple network architecture, the Transformer, based solely on attention mechanisms, dispensing with recurrence and convolutions entirely."
        ),
        Paper(
            id: UUID(),
            title: "BERT: Pre-training of Deep Bidirectional Transformers for Language Understanding",
            authors: "Jacob Devlin, Ming-Wei Chang, Kenton Lee, Kristina Toutanova",
            summary: "We introduce a new language representation model called BERT, which stands for Bidirectional Encoder Representations from Transformers. Unlike recent language representation models, BERT is designed to pre-train deep bidirectional representations from unlabeled text by jointly conditioning on both left and right context in all layers."
        ),
        Paper(
            id: UUID(),
            title: "Deep Residual Learning for Image Recognition",
            authors: "Kaiming He, Xiangyu Zhang, Shaoqing Ren, Jian Sun",
            summary: "Deeper neural networks are more difficult to train. We present a residual learning framework to ease the training of networks that are substantially deeper than those used previously. We explicitly reformulate the layers as learning residual functions with reference to the layer inputs, instead of learning unreferenced functions."
        ),
        Paper(
            id: UUID(),
            title: "Generative Adversarial Nets",
            authors: "Ian J. Goodfellow, Jean Pouget-Abadie, Mehdi Mirza, et al.",
            summary: "We propose a new framework for estimating generative models via an adversarial process, in which we simultaneously train two models: a generative model G that captures the data distribution, and a discriminative model D that estimates the probability that a sample came from the training data rather than G."
        ),
        Paper(
            id: UUID(),
            title: "ImageNet Classification with Deep Convolutional Neural Networks",
            authors: "Alex Krizhevsky, Sutskever, Hinton",
            summary: "We trained a large, deep convolutional neural network to classify the 1.2 million high-resolution images in the ImageNet LSVRC-2010 contest into the 1000 different classes. On the test data, we achieved top-1 and top-5 error rates of 37.5% and 17.0% which is considerably better than the previous state-of-the-art."
        ),
        Paper(
            id: UUID(),
            title: "Playing Atari with Deep Reinforcement Learning",
            authors: "Volodymyr Mnih, Kavukcuoglu, Silver, et al.",
            summary: "We present the first deep learning model to successfully learn control policies directly from high-dimensional sensory input using reinforcement learning. The model is a convolutional neural network, trained with a variant of Q-learning, whose input is raw pixels and whose output is a value function estimating future rewards."
        )
    ]
}
