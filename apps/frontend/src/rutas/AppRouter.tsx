import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";

function HomePage(){
    return(
        <main>
            <h1>ShopCart</h1>
            <p>Plataforma de comercio electrónico</p>
        </main>
    );
}

export function AppRouter(){
    return(
        <BrowserRouter>
            <Routes>
                <Route path='/' element={<HomePage />} />
                <Route path='*' element={<Navigate to={'/'} replace/>}/>
            </Routes>
        </BrowserRouter>
    )
}