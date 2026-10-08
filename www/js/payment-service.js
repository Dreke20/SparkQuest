
const PaymentService = {
    // Mock Products (would match Stripe Price IDs)
    products: {
        'embers100': { name: '100 Embers', price: 0.99, amount: 100, type: 'consumable' },
        'embers500': { name: '500 Embers', price: 4.99, amount: 500, type: 'consumable' },
        'embers1200': { name: '1200 Embers', price: 9.99, amount: 1200, type: 'consumable' },
        'plus': { name: 'Spark+ Subscription', price: 14.99, amount: 0, type: 'subscription' },
        'boost': { name: 'Profile Boost', price: 2.99, amount: 0, type: 'consumable_feature' },
        'superlike': { name: '5 Super Likes', price: 3.99, amount: 5, type: 'consumable_feature' }
    },

    // Prototype Mode: Simulates network request without backend
    async checkout(productId) {
        console.log(`Starting checkout for ${productId}...`);
        const product = this.products[productId];

        if (!product) {
            console.error('Invalid product ID');
            return { error: 'Invalid product' };
        }

        // Simulate Network Delay (Processing Payment)
        return new Promise((resolve) => {
            setTimeout(() => {
                // Success Mock
                const successUrl = new URL(window.location.href);
                successUrl.searchParams.set('payment_status', 'success');
                successUrl.searchParams.set('product_id', productId);

                // Redirect to success URL (simulating Stripe redirect)
                window.location.href = successUrl.toString();
                resolve({ url: successUrl.toString() });
            }, 1500); // 1.5s delay
        });
    },

    // In real app, this would verify session with backend
    verifyPayment(sessionId) {
        return Promise.resolve({ status: 'paid' });
    }
};

export default PaymentService;
